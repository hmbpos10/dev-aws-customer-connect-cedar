# Custom least-privilege security profiles and the agent hierarchy (SPEC §5).
# Permissions are validated against a '*' blanket grant in variables.tf.

resource "aws_connect_security_profile" "this" {
  for_each = var.security_profiles

  instance_id = var.instance_id
  name        = each.key
  description = each.value.description
  permissions = each.value.permissions

  tags = var.tags
}

# Agent hierarchy mirrors the org for reporting isolation. The five levels are
# distinctly-named blocks (not repeatable), so each is emitted conditionally based on
# how many level names were supplied.
resource "aws_connect_user_hierarchy_structure" "this" {
  count = length(var.hierarchy_levels) > 0 ? 1 : 0

  instance_id = var.instance_id

  hierarchy_structure {
    dynamic "level_one" {
      for_each = length(var.hierarchy_levels) >= 1 ? [var.hierarchy_levels[0]] : []
      content {
        name = level_one.value
      }
    }
    dynamic "level_two" {
      for_each = length(var.hierarchy_levels) >= 2 ? [var.hierarchy_levels[1]] : []
      content {
        name = level_two.value
      }
    }
    dynamic "level_three" {
      for_each = length(var.hierarchy_levels) >= 3 ? [var.hierarchy_levels[2]] : []
      content {
        name = level_three.value
      }
    }
    dynamic "level_four" {
      for_each = length(var.hierarchy_levels) >= 4 ? [var.hierarchy_levels[3]] : []
      content {
        name = level_four.value
      }
    }
    dynamic "level_five" {
      for_each = length(var.hierarchy_levels) >= 5 ? [var.hierarchy_levels[4]] : []
      content {
        name = level_five.value
      }
    }
  }
}
