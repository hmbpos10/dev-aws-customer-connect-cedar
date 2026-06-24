# Contact flows from templated JSON (SPEC §5 IVR = templated JSON; ADR 0005).
# Flow definitions live as .tftpl files in the caller; templatefile() injects
# runtime references (queue ARNs, Lex aliases) so flows are not authored inline.

resource "aws_connect_contact_flow" "this" {
  for_each = var.contact_flows

  instance_id = var.instance_id
  name        = each.key
  description = each.value.description
  type        = each.value.type

  content = templatefile(each.value.template_path, each.value.template_vars)

  tags = var.tags
}
