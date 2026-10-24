locals {
  approles = {
    ansible     = ["ansible-policy"]
    opentofu    = ["opentofu-policy"]
    packer      = ["packer-policy"]
    "packer-ci" = ["packer-policy"]
  }
}

resource "vault_approle_auth_backend_role" "this" {
  for_each = local.approles

  backend        = vault_auth_backend.approle.path
  role_name      = each.key
  token_policies = [for p in each.value : vault_policy.this[p].name]
  token_ttl      = 3600
  token_max_ttl  = 14400
}
