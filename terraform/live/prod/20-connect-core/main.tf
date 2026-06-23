module "tags" {
  source = "../../../modules/tagging"

  owner               = var.owner
  cost_centre         = var.cost_centre
  data_classification = "pii"
  extra_tags          = { Layer = "20-connect-core" }
}

locals {
  recordings_cmk_arn = data.terraform_remote_state.security.outputs.cmk_key_arns["recordings"]
  directory_id       = data.terraform_remote_state.security.outputs.directory_id

  # Three segregated operational buckets (SPEC §8: recordings/transcripts/exports kept
  # apart). Shared hardening; each gets its own bucket so lifecycle/retention can diverge.
  storage_buckets = {
    recordings  = "hearts-and-bunnies-connect-recordings"
    transcripts = "hearts-and-bunnies-connect-transcripts"
    exports     = "hearts-and-bunnies-connect-exports"
  }
}

# --- Segregated, CMK-encrypted storage buckets (SPEC §8) ------------------------------
# Versioned, Block Public, Object Lock (governance) — the instance writes recordings,
# transcripts, and scheduled reports here.

module "storage" {
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "5.14.0"
  for_each = local.storage_buckets

  bucket        = each.value
  force_destroy = false

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Object Lock requires versioning; governance mode with a default retention (SPEC §8).
  object_lock_enabled = true
  versioning = {
    enabled = true
  }
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 365
      }
    }
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = local.recordings_cmk_arn
      }
      bucket_key_enabled = true
    }
  }

  tags = module.tags.tags
}

# --- Amazon Connect instance (the hub, SPEC §5) ---------------------------------------

module "connect" {
  source = "../../../modules/connect-instance"

  instance_alias           = var.instance_alias
  identity_management_type = var.identity_management_type
  directory_id             = var.identity_management_type == "EXISTING_DIRECTORY" ? local.directory_id : null

  recordings_bucket_name  = module.storage["recordings"].s3_bucket_id
  transcripts_bucket_name = module.storage["transcripts"].s3_bucket_id
  exports_bucket_name     = module.storage["exports"].s3_bucket_id
  kms_key_arn             = local.recordings_cmk_arn

  # CTR streaming is wired by the analytics layer (Zone 4) to avoid a cross-layer cycle.
  ctr_kinesis_stream_arn = null
}

# --- Routing: hours, queues, routing profiles (SPEC §5) -------------------------------

module "routing" {
  source = "../../../modules/connect-routing"

  instance_id = module.connect.instance_id

  hours_of_operation = {
    business-hours = {
      description = "Mon–Fri 09:00–17:00 London."
      time_zone   = "Europe/London"
      config = [
        for day in ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"] : {
          day        = day
          start_time = { hours = 9, minutes = 0 }
          end_time   = { hours = 17, minutes = 0 }
        }
      ]
    }
  }

  queues = {
    general-support = {
      description             = "Default inbound support queue."
      hours_of_operation_key  = "business-hours"
      outbound_caller_id_name = "Hearts and Bunnies"
    }
  }

  routing_profiles = {
    general-agents = {
      description                = "Default routing profile for general support agents."
      default_outbound_queue_key = "general-support"
      media_concurrencies = [
        { channel = "VOICE", concurrency = 1 },
        { channel = "CHAT", concurrency = 3 },
      ]
      queue_configs = [
        { channel = "VOICE", delay = 0, priority = 1, queue_key = "general-support" },
        { channel = "CHAT", delay = 0, priority = 1, queue_key = "general-support" },
      ]
    }
  }

  tags = module.tags.tags
}

# --- Security profiles + agent hierarchy (SPEC §5: custom least-privilege, not Admin) -

module "security" {
  source = "../../../modules/connect-security"

  instance_id = module.connect.instance_id

  security_profiles = {
    agent = {
      description = "Front-line agent: handle contacts only, no admin."
      permissions = [
        "BasicAgentAccess",
        "OutboundCallAccess",
      ]
    }
    team-lead = {
      description = "Team lead: agent access plus real-time and historical metrics."
      permissions = [
        "BasicAgentAccess",
        "OutboundCallAccess",
        "RealtimeContactLens.View",
        "Metrics.View",
        "HistoricalMetrics.View",
      ]
    }
  }

  hierarchy_levels = ["Division", "Department", "Team"]

  tags = module.tags.tags
}

# --- Contact flow (SPEC §5: templated JSON; ADR 0005) ---------------------------------
# Queue ARN is injected into the template so the flow is not authored inline.

module "contact_flows" {
  source = "../../../modules/connect-contact-flow"

  instance_id = module.connect.instance_id

  contact_flows = {
    inbound-main = {
      description   = "Primary inbound flow: greet, then transfer to general support."
      type          = "CONTACT_FLOW"
      template_path = "${path.module}/flows/inbound-main.json.tftpl"
      template_vars = {
        queue_arn = module.routing.queue_arns["general-support"]
      }
    }
  }

  tags = module.tags.tags
}
