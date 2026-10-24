import {
  to = vault_mount.secret
  id = "secret"
}

import {
  to = vault_auth_backend.approle
  id = "approle"
}

import {
  for_each = toset(["ansible-policy", "opentofu-policy", "packer-policy"])
  to       = vault_policy.this[each.key]
  id       = each.key
}

import {
  for_each = local.approles
  to       = vault_approle_auth_backend_role.this[each.key]
  id       = "auth/approle/role/${each.key}"
}
