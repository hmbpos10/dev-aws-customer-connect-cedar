# connect-security

Custom least-privilege Connect security profiles and the agent hierarchy structure
(SPEC §5). A `validation` block rejects any profile containing a `*` permission so no
blanket-Admin profile can be created.

## Usage

```hcl
module "connect_security" {
  source      = "../../../modules/connect-security"
  instance_id = module.connect.instance_id

  security_profiles = {
    "agent" = {
      description = "Front-line agent — handle contacts only"
      permissions = ["BasicAgentAccess", "OutboundCallAccess"]
    }
    "team-lead" = {
      description = "Team lead — agent plus real-time metrics"
      permissions = ["BasicAgentAccess", "RealtimeContactLens.View"]
    }
  }

  hierarchy_levels = ["Division", "Department", "Team"]

  tags = module.tags.tags
}
```

## Notes

- Permission strings are Connect security-profile permissions; verify the exact names in
  the Connect admin model. `*` is rejected by design.
- `hierarchy_levels` is ordered (level one first), max five entries.
