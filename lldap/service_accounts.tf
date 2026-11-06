locals {
  service_accounts = {
    authelia = {
      display_name = "Authelia"
      groups       = ["lldap_password_manager"]
    }
  }
}

resource "lldap_user" "service_account" {
  for_each     = local.service_accounts
  username     = each.key
  email        = "${each.key}@macopla.com"
  display_name = each.value.display_name
}

resource "lldap_user_memberships" "service_account" {
  for_each  = local.service_accounts
  user_id   = lldap_user.service_account[each.key].id
  group_ids = [for g in each.value.groups : local.group_ids[g]]
}
