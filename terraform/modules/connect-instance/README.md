# connect-instance

Amazon Connect instance (SPEC §5) with CMK-encrypted storage configs for call
recordings, chat transcripts, and scheduled reports, plus optional Contact Trace Record
streaming to Kinesis. Auth is SAML or an existing directory — `CONNECT_MANAGED` is
rejected by validation (SPEC §5: not the default admin).

## Usage

```hcl
module "connect" {
  source = "../../../modules/connect-instance"

  instance_alias           = "hearts-and-bunnies"
  identity_management_type = "SAML"

  recordings_bucket_name  = module.recordings_bucket.s3_bucket_id
  transcripts_bucket_name = module.transcripts_bucket.s3_bucket_id
  exports_bucket_name     = module.exports_bucket.s3_bucket_id
  kms_key_arn             = module.connect_cmk.key_arn

  # Wired later by the analytics layer:
  ctr_kinesis_stream_arn = null
}
```

## Notes

- `kms_key_arn` must be the **full ARN**, not the key ID (provider requirement).
- CTR streaming stays off until `ctr_kinesis_stream_arn` is supplied, avoiding a
  cross-layer cycle with the analytics pipeline.
