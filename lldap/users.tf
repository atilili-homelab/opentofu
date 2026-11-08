data "vault_kv_secrets_list_v2" "identities" {
  mount = "secret"
  name  = "identities"
}

data "vault_generic_secret" "identity" {
  for_each = toset(nonsensitive(data.vault_kv_secrets_list_v2.identities.names))
  path     = "secret/identities/${each.key}"
}

locals {
  users = {
    for name, secret in data.vault_generic_secret.identity : name => {
      email        = secret.data["email"]
      display_name = secret.data["display_name"]
      groups       = split(",", nonsensitive(secret.data["groups"]))
    }
  }
  user_groups = toset(flatten([for user in local.users : user.groups]))
}

resource "lldap_group" "this" {
  for_each     = local.user_groups
  display_name = each.key
}

resource "lldap_user" "person" {
  for_each     = local.users
  username     = each.key
  email        = each.value.email
  display_name = each.value.display_name
}

resource "lldap_user_memberships" "person" {
  for_each  = local.users
  user_id   = lldap_user.person[each.key].id
  group_ids = [for group in each.value.groups : lldap_group.this[group].id]
}
