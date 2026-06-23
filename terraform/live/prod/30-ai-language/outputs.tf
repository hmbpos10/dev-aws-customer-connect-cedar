output "bot_id" {
  description = "Lex V2 bot identifier."
  value       = module.support_bot.bot_id
}

output "bot_version" {
  description = "Published Lex V2 bot version."
  value       = module.support_bot.bot_version
}

output "lex_role_arn" {
  description = "Execution role ARN assumed by the Lex V2 bot."
  value       = aws_iam_role.lex.arn
}

output "vocabulary_id" {
  description = "Custom vocabulary identifier."
  value       = aws_connect_vocabulary.brand_terms.vocabulary_id
}
