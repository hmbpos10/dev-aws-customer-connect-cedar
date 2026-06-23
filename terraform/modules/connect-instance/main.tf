# Amazon Connect instance (the hub, SPEC §5) plus its CMK-encrypted storage configs.
# Auth is SAML/Directory — never the default CONNECT_MANAGED admin.

resource "aws_connect_instance" "this" {
  instance_alias           = var.instance_alias
  identity_management_type = var.identity_management_type
  directory_id             = var.directory_id

  inbound_calls_enabled  = var.inbound_calls_enabled
  outbound_calls_enabled = var.outbound_calls_enabled

  # Contact-flow logs to CloudWatch and Contact Lens analytics on (SPEC §6, §10).
  contact_flow_logs_enabled = true
  contact_lens_enabled      = var.contact_lens_enabled

  tags = var.tags
}

# Call recordings -> S3, CMK-encrypted.
resource "aws_connect_instance_storage_config" "call_recordings" {
  instance_id   = aws_connect_instance.this.id
  resource_type = "CALL_RECORDINGS"

  storage_config {
    storage_type = "S3"

    s3_config {
      bucket_name   = var.recordings_bucket_name
      bucket_prefix = "call-recordings"

      encryption_config {
        encryption_type = "KMS"
        key_id          = var.kms_key_arn
      }
    }
  }
}

# Chat transcripts -> S3, CMK-encrypted.
resource "aws_connect_instance_storage_config" "chat_transcripts" {
  instance_id   = aws_connect_instance.this.id
  resource_type = "CHAT_TRANSCRIPTS"

  storage_config {
    storage_type = "S3"

    s3_config {
      bucket_name   = var.transcripts_bucket_name
      bucket_prefix = "chat-transcripts"

      encryption_config {
        encryption_type = "KMS"
        key_id          = var.kms_key_arn
      }
    }
  }
}

# Scheduled reports / exports -> S3, CMK-encrypted.
resource "aws_connect_instance_storage_config" "scheduled_reports" {
  instance_id   = aws_connect_instance.this.id
  resource_type = "SCHEDULED_REPORTS"

  storage_config {
    storage_type = "S3"

    s3_config {
      bucket_name   = var.exports_bucket_name
      bucket_prefix = "scheduled-reports"

      encryption_config {
        encryption_type = "KMS"
        key_id          = var.kms_key_arn
      }
    }
  }
}

# Contact Trace Records -> Kinesis Data Stream (the streaming pipeline, SPEC §8).
# Only created once the analytics layer has provisioned the stream.
resource "aws_connect_instance_storage_config" "contact_trace_records" {
  count = var.ctr_kinesis_stream_arn == null ? 0 : 1

  instance_id   = aws_connect_instance.this.id
  resource_type = "CONTACT_TRACE_RECORDS"

  storage_config {
    storage_type = "KINESIS_STREAM"

    kinesis_stream_config {
      stream_arn = var.ctr_kinesis_stream_arn
    }
  }
}
