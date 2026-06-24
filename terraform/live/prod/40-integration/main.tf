module "tags" {
  source = "../../../modules/tagging"

  owner               = var.owner
  cost_centre         = var.cost_centre
  data_classification = "internal"
  extra_tags          = { Layer = "40-integration" }
}

locals {
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  lambda_sg_id       = data.terraform_remote_state.network.outputs.lambda_security_group_id
  logs_cmk_arn       = data.terraform_remote_state.security.outputs.cmk_key_arns["logs"]
  sns_cmk_id         = data.terraform_remote_state.security.outputs.cmk_key_ids["sns"]
  instance_arn       = data.terraform_remote_state.connect_core.outputs.instance_arn
}

# --- SQS: contact-event queue + DLQ (SPEC §7: decouple Lambda, retry handling) --------

module "contact_events_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name = "connect-contact-events"

  # CMK encryption (SPEC §3). DLQ created by the module with the same CMK.
  kms_master_key_id     = local.sns_cmk_id
  dlq_kms_master_key_id = local.sns_cmk_id

  create_dlq = true
  redrive_policy = {
    maxReceiveCount = 5
  }

  visibility_timeout_seconds = 180

  tags = module.tags.tags
}

# --- SNS: alert topic, CMK-encrypted (SPEC §7) ----------------------------------------

module "alerts_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  name = "connect-platform-alerts"

  # CMK-encrypted topic (SPEC §3).
  kms_master_key_id = local.sns_cmk_id

  tags = module.tags.tags
}

# --- Lambda: contact-event processor (VPC-attached, DLQ, CMK env — SPEC §7) -----------

module "contact_events_fn" {
  source = "../../../modules/lambda-fn"

  function_name = "connect-contact-events"
  description   = "Processes Connect contact events from SQS."
  handler       = "app.handler"
  runtime       = "python3.11"
  source_path   = "${path.module}/src/contact-events"

  vpc_subnet_ids         = local.private_subnet_ids
  vpc_security_group_ids = [local.lambda_sg_id]

  dead_letter_target_arn = module.contact_events_queue.dead_letter_queue_arn
  kms_key_arn            = local.logs_cmk_arn

  reserved_concurrent_executions = 10

  tags = module.tags.tags
}

# SQS -> Lambda event source mapping.
resource "aws_lambda_event_source_mapping" "contact_events" {
  event_source_arn = module.contact_events_queue.queue_arn
  function_name    = module.contact_events_fn.alias_arn
  batch_size       = 10
  enabled          = true

  tags = module.tags.tags
}

# Allow the function's role to consume from the queue and decrypt with the CMK.
data "aws_iam_policy_document" "fn_sqs" {
  statement {
    sid    = "ConsumeQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [module.contact_events_queue.queue_arn]
  }

  statement {
    sid    = "UseCmk"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [data.terraform_remote_state.security.outputs.cmk_key_arns["sns"]]
  }
}

resource "aws_iam_role_policy" "fn_sqs" {
  name   = "consume-contact-events"
  role   = module.contact_events_fn.role_name
  policy = data.aws_iam_policy_document.fn_sqs.json
}

# --- EventBridge: Connect contact events -> SQS (SPEC §7) -----------------------------

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  # Use the default bus; AWS service events are delivered there.
  create_bus = false

  rules = {
    connect-contact-events = {
      description = "Amazon Connect contact events for this instance."
      event_pattern = jsonencode({
        source      = ["aws.connect"]
        detail-type = ["Amazon Connect Contact Event"]
        resources   = [local.instance_arn]
      })
    }
  }

  targets = {
    connect-contact-events = [
      {
        name            = "to-contact-events-queue"
        arn             = module.contact_events_queue.queue_arn
        dead_letter_arn = module.contact_events_queue.dead_letter_queue_arn
      }
    ]
  }

  # The module manages the SQS access policy needed for EventBridge to deliver.
  attach_sqs_policy = true
  sqs_target_arns   = [module.contact_events_queue.queue_arn]

  tags = module.tags.tags
}

# --- Step Functions: contact orchestration (SPEC §7) ----------------------------------

module "contact_orchestrator" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "5.1.0"

  name = "connect-contact-orchestrator"
  type = "STANDARD"

  definition = jsonencode({
    Comment = "Skeleton orchestration; invokes the contact-events function then completes."
    StartAt = "ProcessContact"
    States = {
      ProcessContact = {
        Type     = "Task"
        Resource = module.contact_events_fn.alias_arn
        End      = true
      }
    }
  })

  # Logging to CloudWatch, CMK-encrypted log group.
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = [module.contact_events_fn.qualified_arn, module.contact_events_fn.alias_arn]
      }
    ]
  })

  service_integrations = {
    lambda = {
      lambda = [module.contact_events_fn.alias_arn, module.contact_events_fn.qualified_arn]
    }
  }

  tags = module.tags.tags
}
