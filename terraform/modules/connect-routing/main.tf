# Connect routing primitives: hours of operation, queues, routing profiles
# (SPEC §5). Driven by maps with for_each so resource addresses are stable when
# entries are added or removed (skill: never use list index as identity).

resource "aws_connect_hours_of_operation" "this" {
  for_each = var.hours_of_operation

  instance_id = var.instance_id
  name        = each.key
  description = each.value.description
  time_zone   = each.value.time_zone

  dynamic "config" {
    for_each = each.value.config
    content {
      day = config.value.day
      start_time {
        hours   = config.value.start_time.hours
        minutes = config.value.start_time.minutes
      }
      end_time {
        hours   = config.value.end_time.hours
        minutes = config.value.end_time.minutes
      }
    }
  }

  tags = var.tags
}

resource "aws_connect_queue" "this" {
  for_each = var.queues

  instance_id           = var.instance_id
  name                  = each.key
  description           = each.value.description
  hours_of_operation_id = aws_connect_hours_of_operation.this[each.value.hours_of_operation_key].hours_of_operation_id
  max_contacts          = each.value.max_contacts
  status                = each.value.status

  outbound_caller_config {
    outbound_caller_id_name = each.value.outbound_caller_id_name
  }

  tags = var.tags
}

resource "aws_connect_routing_profile" "this" {
  for_each = var.routing_profiles

  instance_id               = var.instance_id
  name                      = each.key
  description               = each.value.description
  default_outbound_queue_id = aws_connect_queue.this[each.value.default_outbound_queue_key].queue_id

  dynamic "media_concurrencies" {
    for_each = each.value.media_concurrencies
    content {
      channel     = media_concurrencies.value.channel
      concurrency = media_concurrencies.value.concurrency
    }
  }

  dynamic "queue_configs" {
    for_each = each.value.queue_configs
    content {
      channel  = queue_configs.value.channel
      delay    = queue_configs.value.delay
      priority = queue_configs.value.priority
      queue_id = aws_connect_queue.this[queue_configs.value.queue_key].queue_id
    }
  }

  tags = var.tags
}
