# ============================ #
# ==== COMPTES DE SERVICE ==== #
# ============================ #
locals {
  service_accounts = {
    ansible    = { comment = "Ansible Inventory (read only)", role = "PVEAuditor" }
    homarr     = { comment = "Homarr Integration (read only)", role = "PVEAuditor" }
    prometheus = { comment = "Exporter Prometheus (read only)", role = "PVEAuditor" }
    pdm        = { comment = "Proxmox Datacenter Manager (read only)", role = "PVEAuditor" }
  }
}
resource "proxmox_virtual_environment_user" "service" {
  for_each = local.service_accounts
  user_id  = "${each.key}@pve"
  comment  = each.value.comment
  enabled  = true
}
resource "proxmox_acl" "service" {
  for_each  = local.service_accounts
  path      = "/"
  role_id   = each.value.role
  user_id   = proxmox_virtual_environment_user.service[each.key].user_id
  propagate = true
}

# =========================== #
# ====== ADMINISTRATOR ====== #
# =========================== #
resource "proxmox_acl" "admin_administrator" {
  group_id  = "admin"
  path      = "/"
  propagate = true
  role_id   = "Administrator"
  token_id  = null
  user_id   = null
}
resource "proxmox_virtual_environment_group" "admin" {
  comment  = ""
  group_id = "admin"
}

# ============================ #
# ========= OPENTOFU ========= #
# ============================ #
resource "proxmox_virtual_environment_user" "opentofu" {
  user_id = "opentofu@pve"
  comment = "OpenTofu, token cree manuellement hors du code"
  enabled = true
  lifecycle {
    prevent_destroy = true
  }
}
resource "proxmox_acl" "opentofu" {
  path      = "/"
  role_id   = "Administrator"
  user_id   = proxmox_virtual_environment_user.opentofu.user_id
  propagate = true
  lifecycle {
    prevent_destroy = true
  }
}

# ============================ #
# ========== PACKER ========== #
# ============================ #
resource "proxmox_virtual_environment_user" "packer" {
  user_id = "packer@pve"
  comment = "Construction des templates Packer"
  enabled = true
}
resource "proxmox_user_token" "packer" {
  user_id               = proxmox_virtual_environment_user.packer.user_id
  token_name            = "packer"
  comment               = "Token Packer, gere par OpenTofu"
  privileges_separation = false
}
resource "proxmox_virtual_environment_role" "packer" {
  role_id = "Packer"
  privileges = [
    "VM.Allocate", "VM.Audit", "VM.Console", "VM.PowerMgmt", "VM.GuestAgent.Audit", "VM.Config.CDROM", "VM.Config.CPU", "VM.Config.Cloudinit", "VM.Config.Disk", "VM.Config.HWType", "VM.Config.Memory", "VM.Config.Network", "VM.Config.Options", "Datastore.AllocateSpace", "Datastore.Audit", "SDN.Use",
  ]
}
resource "proxmox_acl" "packer" {
  path      = "/"
  role_id   = proxmox_virtual_environment_role.packer.role_id
  user_id   = proxmox_virtual_environment_user.packer.user_id
  propagate = true
}
resource "vault_kv_secret_v2" "packer_token" {
  mount = "secret"
  name  = "packer/proxmox-token"

  data_json_wo         = jsonencode({ token = split("=", proxmox_user_token.packer.value)[1] })
  data_json_wo_version = 2
}
