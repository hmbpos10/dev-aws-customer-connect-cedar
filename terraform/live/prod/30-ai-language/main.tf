module "tags" {
  source = "../../../modules/tagging"

  owner               = var.owner
  cost_centre         = var.cost_centre
  data_classification = "confidential"
  extra_tags          = { Layer = "30-ai-language" }
}

locals {
  instance_id = data.terraform_remote_state.connect_core.outputs.instance_id

  # en_GB (Lex locale id) -> en-GB (Transcribe/vocabulary language code).
  vocabulary_language_code = replace(var.locale_id, "_", "-")
}

# --- Lex V2 execution role (SPEC §6) --------------------------------------------------
# Lex V2 assumes lexv2.amazonaws.com (verified against provider docs at build time).

data "aws_iam_policy_document" "lex_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lexv2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lex" {
  name               = "${var.bot_name}-lex-role"
  assume_role_policy = data.aws_iam_policy_document.lex_assume.json

  tags = module.tags.tags
}

# Lex needs Polly synthesis for spoken prompts; scoped to the synth action only.
data "aws_iam_policy_document" "lex" {
  statement {
    sid       = "PollySynthesis"
    effect    = "Allow"
    actions   = ["polly:SynthesizeSpeech"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lex" {
  name   = "lex-runtime"
  role   = aws_iam_role.lex.id
  policy = data.aws_iam_policy_document.lex.json
}

# --- Lex V2 bot (bot + locale + published version; alias via CLI — ADR 0005) ----------

module "support_bot" {
  source = "../../../modules/lex-bot"

  name        = var.bot_name
  description = "Self-service support bot for the hearts-and-bunnies contact centre."
  role_arn    = aws_iam_role.lex.arn
  locale_id   = var.locale_id
  voice_id    = var.voice_id
  alias_name  = var.bot_alias_name

  tags = module.tags.tags
}

# A minimal intent on the DRAFT locale so the published version is non-empty. Authored
# before the version snapshot is taken (depends_on enforces the ordering).
resource "aws_lexv2models_intent" "speak_to_agent" {
  bot_id      = module.support_bot.bot_id
  bot_version = "DRAFT"
  locale_id   = var.locale_id
  name        = "SpeakToAgent"

  sample_utterance { utterance = "I want to speak to an agent" }
  sample_utterance { utterance = "Talk to a person" }
  sample_utterance { utterance = "Connect me to support" }
}

# --- Associate the Lex V2 bot with the Connect instance (provider gap — ADR 0005) -----
# aws_connect_bot_association only supports Lex V1; the V2 association has no native
# resource, so it is created via the Connect API. Keyed to the published bot version so a
# new version re-associates the alias.

resource "null_resource" "lex_v2_association" {
  triggers = {
    instance_id = local.instance_id
    bot_alias   = module.support_bot.bot_id
    bot_version = module.support_bot.bot_version
    region      = var.region
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      ALIAS_ARN=$(aws lexv2-models list-bot-aliases \
        --bot-id "${module.support_bot.bot_id}" \
        --region "${var.region}" \
        --query "botAliasSummaries[?botAliasName=='${var.bot_alias_name}'].botAliasId" \
        --output text)
      aws connect associate-bot \
        --instance-id "${local.instance_id}" \
        --region "${var.region}" \
        --lex-v2-bot AliasArn="arn:aws:lex:${var.region}:$(aws sts get-caller-identity --query Account --output text):bot-alias/${module.support_bot.bot_id}/$ALIAS_ARN"
    EOT
  }

  depends_on = [module.support_bot]
}

# --- Custom vocabulary for Transcribe / Contact Lens (SPEC §6) ------------------------
# Improves recognition of brand terms in transcripts. TAB-separated PLS-style content.

resource "aws_connect_vocabulary" "brand_terms" {
  instance_id   = local.instance_id
  name          = "hearts-and-bunnies-brand-terms"
  language_code = local.vocabulary_language_code
  content       = "Phrase\tIPA\tSoundsLike\tDisplayAs\nHearts-and-Bunnies\t\t\tHearts and Bunnies"

  tags = module.tags.tags
}

# --- Polly lexicons (SPEC §6: TF±; no native resource — ADR 0005) ---------------------
# Pushed via the CLI, keyed by a content hash so edits re-apply idempotently.

resource "null_resource" "polly_lexicon" {
  for_each = var.polly_lexicons

  triggers = {
    name         = each.key
    content_hash = sha256(each.value.content)
    region       = var.region
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      aws polly put-lexicon \
        --name "${each.key}" \
        --region "${var.region}" \
        --content '${each.value.content}'
    EOT
  }
}

# Contact Lens redaction note (SPEC §6): redaction/analytics policy is configured per
# contact flow (Set recording and analytics behavior block) and on the instance, not via
# an aws_connect_rule resource — that resource does not exist in the provider (verified at
# build time; ADR 0005). PCI/PII redaction is enabled in the 20-connect-core flow.
