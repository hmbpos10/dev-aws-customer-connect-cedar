# connect-routing

Connect routing primitives (SPEC §5): hours of operation, queues, and routing profiles.
Driven by maps with `for_each` so resource addresses stay stable as entries are added or
removed. Queues reference hours by key; routing profiles reference queues by key — the
module resolves the generated IDs internally.

## Usage

```hcl
module "routing" {
  source      = "../../../modules/connect-routing"
  instance_id = module.connect.instance_id

  hours_of_operation = {
    "uk-business-hours" = {
      time_zone = "Europe/London"
      config = [{
        day        = "MONDAY"
        start_time = { hours = 9, minutes = 0 }
        end_time   = { hours = 17, minutes = 30 }
      }]
    }
  }

  queues = {
    "general-support" = { hours_of_operation_key = "uk-business-hours" }
  }

  routing_profiles = {
    "default" = {
      description                = "Default voice + chat routing"
      default_outbound_queue_key = "general-support"
      media_concurrencies        = [{ channel = "VOICE", concurrency = 1 }]
      queue_configs = [{
        channel = "VOICE", delay = 0, priority = 1, queue_key = "general-support"
      }]
    }
  }

  tags = module.tags.tags
}
```
