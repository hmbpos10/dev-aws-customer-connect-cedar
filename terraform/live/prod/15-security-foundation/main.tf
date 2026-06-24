module "tags" {
  source = "../../../modules/tagging"

  owner               = var.owner
  cost_centre         = var.cost_centre
  data_classification = "confidential"
  extra_tags          = { Layer = "15-security-foundation" }
}

# --- Customer-managed KMS keys (SPEC §3: CMK everywhere) ------------------------------
# One CMK per data domain so a key compromise/rotation is scoped to one concern. Keys are
# consumed by downstream layers (20-connect-core, 40-integration, Zone 4) through
# terraform_remote_state. Service principals are region-qualified where the service emits
# region-scoped principals (CloudWatch Logs).

locals {
  logs_principal = "logs.${var.region}.amazonaws.com"

  cmks = {
    recordings = {
      alias_name         = "connect/recordings"
      description        = "Connect call recordings and chat transcripts at rest (SPEC §3)."
      service_principals = ["connect.amazonaws.com"]
    }
    dynamodb = {
      alias_name         = "connect/dynamodb"
      description        = "DynamoDB session/contact state encryption (SPEC §8)."
      service_principals = ["dynamodb.amazonaws.com"]
    }
    kinesis = {
      alias_name         = "connect/kinesis"
      description        = "Kinesis Data Streams + Firehose CTR pipeline (SPEC §8)."
      service_principals = ["kinesis.amazonaws.com", "firehose.amazonaws.com"]
    }
    logs = {
      alias_name         = "connect/logs"
      description        = "CloudWatch Logs encryption across the platform (SPEC §3, §10)."
      service_principals = [local.logs_principal]
    }
    sns = {
      alias_name         = "connect/sns"
      description        = "SNS topic encryption for alerts and fan-out (SPEC §7)."
      service_principals = ["sns.amazonaws.com", "cloudwatch.amazonaws.com"]
    }
    secrets = {
      alias_name         = "connect/secrets"
      description        = "Secrets Manager secret encryption (SPEC §9)."
      service_principals = ["secretsmanager.amazonaws.com"]
    }
  }
}

module "cmk" {
  source   = "../../../modules/kms-cmk"
  for_each = local.cmks

  alias_name         = each.value.alias_name
  description        = each.value.description
  service_principals = each.value.service_principals
  key_administrators = var.key_administrators

  tags = module.tags.tags
}

# --- IAM permission boundary (SPEC §9: least privilege, boundaries) -------------------
# Attached to every workload role (one role per Lambda) downstream so no role can exceed
# the platform's blast radius: it caps the region to eu-west-2 and forbids IAM/Org/account
# escalation and disabling the detective controls.

data "aws_iam_policy_document" "permission_boundary" {
  statement {
    sid       = "AllowRegionalServices"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # Global services that have no regional endpoint must remain usable.
  statement {
    sid    = "AllowGlobalServices"
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
      "sts:AssumeRole",
      "sts:GetCallerIdentity",
      "cloudfront:Get*",
      "cloudfront:List*",
      "route53:Get*",
      "route53:List*",
      "support:*",
    ]
    resources = ["*"]
  }

  # Hard ceiling: no privilege escalation, no tampering with org/account controls or the
  # security services, regardless of what a role's own policy grants.
  statement {
    sid    = "DenyEscalationAndTampering"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:DeleteRolePermissionsBoundary",
      "iam:PutRolePermissionsBoundary",
      "organizations:*",
      "account:*",
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "guardduty:DeleteDetector",
      "guardduty:DisassociateFromMasterAccount",
      "securityhub:DisableSecurityHub",
      "kms:ScheduleKeyDeletion",
      "kms:DisableKey",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "permission_boundary" {
  name        = "connect-workload-permission-boundary"
  description = "Permission boundary for all platform workload roles (SPEC §9)."
  policy      = data.aws_iam_policy_document.permission_boundary.json

  tags = module.tags.tags
}

# --- Secrets Manager: Managed AD admin password (CMK-encrypted, rotation-ready) -------

resource "aws_secretsmanager_secret" "directory_admin" {
  name        = var.directory_admin_secret_name
  description = "Managed Microsoft AD admin password for Connect agent auth."
  kms_key_id  = module.cmk["secrets"].key_arn

  # Recovery window so an accidental delete is reversible (SPEC §9).
  recovery_window_in_days = 30

  tags = module.tags.tags
}

# Generated out of band and stored here; never hard-coded (CLAUDE.md). The directory below
# reads the current value. Rotation is wired in a follow-up via a rotation Lambda.
resource "aws_secretsmanager_secret_version" "directory_admin" {
  secret_id     = aws_secretsmanager_secret.directory_admin.id
  secret_string = random_password.directory_admin.result
}

resource "random_password" "directory_admin" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# --- Directory Service: Managed Microsoft AD (SPEC §4: agent auth via Managed AD) ------
# Lives in the private subnets exported by 10-network; Connect federates against it.

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "connect-customer-terraform-github-actions"
    key    = "prod/10-network/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_directory_service_directory" "connect" {
  name     = var.directory_name
  password = random_password.directory_admin.result
  type     = "MicrosoftAD"
  edition  = var.directory_edition

  vpc_settings {
    vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
    subnet_ids = slice(data.terraform_remote_state.network.outputs.private_subnet_ids, 0, 2)
  }

  tags = module.tags.tags
}

# --- IAM Identity Center permission sets (SPEC §4: engineer/admin access, no IAM users) -
# Administered from the management account. The SSO instance is discovered, not created.

data "aws_ssoadmin_instances" "this" {
  provider = aws.management
}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

resource "aws_ssoadmin_permission_set" "this" {
  provider = aws.management
  for_each = var.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = local.sso_instance_arn
  session_duration = each.value.session_duration

  tags = module.tags.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  provider = aws.management
  for_each = {
    for pair in flatten([
      for ps_name, ps in var.permission_sets : [
        for arn in ps.managed_policy_arns : {
          key                = "${ps_name}:${arn}"
          permission_set_key = ps_name
          managed_policy_arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set_key].arn
  managed_policy_arn = each.value.managed_policy_arn
}
