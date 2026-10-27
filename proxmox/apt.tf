resource "proxmox_apt_standard_repository" "no_subscription" {
  for_each = var.nodes
  node     = each.key
  handle   = "no-subscription"
}

resource "proxmox_apt_repository" "no_subscription" {
  for_each  = var.nodes
  node      = each.key
  file_path = proxmox_apt_standard_repository.no_subscription[each.key].file_path
  index     = proxmox_apt_standard_repository.no_subscription[each.key].index
  enabled   = true
}
