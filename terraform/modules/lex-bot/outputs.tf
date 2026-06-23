output "bot_id" {
  description = "Identifier of the Lex V2 bot."
  value       = aws_lexv2models_bot.this.id
}

output "bot_version" {
  description = "Published bot version number."
  value       = aws_lexv2models_bot_version.this.bot_version
}

output "locale_id" {
  description = "Locale configured on the bot."
  value       = aws_lexv2models_bot_locale.this.locale_id
}
