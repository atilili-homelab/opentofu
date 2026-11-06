data "lldap_groups" "all" {}

locals {
  group_ids = { for g in data.lldap_groups.all.groups : g.display_name => g.id }
}
