# Amazon Lex V2 bot (SPEC §6). The provider covers bot, locale, and version natively;
# bot ALIASES have no resource, so the alias is created via CLI (ADR 0005).

resource "aws_lexv2models_bot" "this" {
  name                        = var.name
  description                 = var.description
  role_arn                    = var.role_arn
  idle_session_ttl_in_seconds = var.idle_session_ttl_in_seconds
  type                        = "Bot"

  data_privacy {
    child_directed = var.child_directed
  }

  tags = var.tags
}

resource "aws_lexv2models_bot_locale" "this" {
  bot_id                           = aws_lexv2models_bot.this.id
  bot_version                      = "DRAFT"
  locale_id                        = var.locale_id
  n_lu_intent_confidence_threshold = var.nlu_intent_confidence_threshold

  voice_settings {
    voice_id = var.voice_id
    engine   = "neural"
  }
}

resource "aws_lexv2models_bot_version" "this" {
  bot_id = aws_lexv2models_bot.this.id

  locale_specification = {
    (var.locale_id) = {
      source_bot_version = "DRAFT"
    }
  }

  # The version snapshots the DRAFT locale; recreate when the locale changes.
  depends_on = [aws_lexv2models_bot_locale.this]
}

# Bot alias — no native resource (provider gap, verified at build time). Created and
# pointed at the published version via the CLI, re-run when the version changes.
resource "null_resource" "bot_alias" {
  triggers = {
    bot_id      = aws_lexv2models_bot.this.id
    bot_version = aws_lexv2models_bot_version.this.bot_version
    alias_name  = var.alias_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      EXISTING=$(aws lexv2-models list-bot-aliases \
        --bot-id "${aws_lexv2models_bot.this.id}" \
        --query "botAliasSummaries[?botAliasName=='${var.alias_name}'].botAliasId" \
        --output text)
      if [ -z "$EXISTING" ] || [ "$EXISTING" = "None" ]; then
        aws lexv2-models create-bot-alias \
          --bot-id "${aws_lexv2models_bot.this.id}" \
          --bot-alias-name "${var.alias_name}" \
          --bot-version "${aws_lexv2models_bot_version.this.bot_version}"
      else
        aws lexv2-models update-bot-alias \
          --bot-id "${aws_lexv2models_bot.this.id}" \
          --bot-alias-id "$EXISTING" \
          --bot-alias-name "${var.alias_name}" \
          --bot-version "${aws_lexv2models_bot_version.this.bot_version}"
      fi
    EOT
  }
}
