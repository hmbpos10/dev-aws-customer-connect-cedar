module "tags" {
  source = "../../../modules/tagging"

  owner               = var.owner
  cost_centre         = var.cost_centre
  data_classification = "internal"
  extra_tags          = { Layer = "10-network" }
}

# --- VPC: private subnets only; workloads never public (SPEC §4) ----------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "connect-platform"
  cidr = var.vpc_cidr_block

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = [] # no public subnets — egress is via endpoints/DNS firewall

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = module.tags.tags
}

# --- Flow logs (SPEC §4: VPC Flow Logs; central aggregation noted) --------------------

# Dedicated CMK for the flow-logs group. Kept in THIS layer rather than consuming the
# shared logs CMK from 15-security-foundation: 15 already reads 10-network's remote state
# for the VPC, so sourcing a key from 15 here would create a circular layer dependency
# (SPEC §13 blast-radius layering). CloudWatch Logs needs an explicit key-policy grant.
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "flow_logs_cmk" {
  # Account root retains administrative control of the key.
  statement {
    sid       = "EnableRoot"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Allow CloudWatch Logs in this region to use the key, scoped to this log group.
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/vpc/connect-platform/flow-logs"]
    }
  }
}

resource "aws_kms_key" "flow_logs" {
  description             = "CMK for VPC flow-logs CloudWatch group (SPEC §3)."
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.flow_logs_cmk.json

  tags = module.tags.tags
}

resource "aws_kms_alias" "flow_logs" {
  name          = "alias/connect/flow-logs"
  target_key_id = aws_kms_key.flow_logs.key_id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/vpc/connect-platform/flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.flow_logs.arn

  tags = module.tags.tags
}

data "aws_iam_policy_document" "flow_logs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.flow_logs.arn}:*"]
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "connect-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume.json

  tags = module.tags.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name   = "flow-logs-delivery"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs.json
}

resource "aws_flow_log" "vpc" {
  vpc_id                   = module.vpc.vpc_id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn             = aws_iam_role.flow_logs.arn
  max_aggregation_interval = 60

  tags = module.tags.tags
}

# --- Security groups (least-privilege; v6 map-of-object rules) ------------------------

module "endpoints_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  name        = "connect-vpc-endpoints"
  description = "HTTPS from the VPC to interface endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    https_from_vpc = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr_block
      description = "HTTPS from within the VPC"
    }
  }

  egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all egress"
    }
  }

  tags = module.tags.tags
}

module "lambda_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  name        = "connect-lambda"
  description = "Egress-only SG for VPC-attached Lambda"
  vpc_id      = module.vpc.vpc_id

  egress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr_block
      description = "HTTPS to in-VPC endpoints"
    }
  }

  tags = module.tags.tags
}

# --- VPC endpoints: keep S3/DynamoDB/Secrets/Kinesis off the public internet ----------

resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(["s3", "dynamodb"])

  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(module.tags.tags, { Name = "connect-${each.value}-gw" })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(["secretsmanager", "kinesis-streams", "kms"])

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.endpoints_sg.id]
  private_dns_enabled = true

  tags = merge(module.tags.tags, { Name = "connect-${each.value}-if" })
}

# --- DNS Firewall on egress (SPEC §4) -------------------------------------------------

resource "aws_route53_resolver_firewall_domain_list" "blocked" {
  name    = "connect-blocked-domains"
  domains = ["malware.example.", "phishing.example."]

  tags = module.tags.tags
}

resource "aws_route53_resolver_firewall_rule_group" "this" {
  name = "connect-dns-firewall"

  tags = module.tags.tags
}

resource "aws_route53_resolver_firewall_rule" "block" {
  name                    = "block-listed-domains"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.blocked.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.this.id
  priority                = 100
}

resource "aws_route53_resolver_firewall_rule_group_association" "this" {
  name                   = "connect-dns-firewall-assoc"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.this.id
  vpc_id                 = module.vpc.vpc_id
  priority               = 101

  tags = module.tags.tags
}
