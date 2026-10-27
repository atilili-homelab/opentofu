# =========================== #
# ====== ADMINISTRATOR ====== #
# =========================== #
locals {
  admin_users = toset(["yoann", "guillaume"])
}
resource "proxmox_virtual_environment_user" "admin" {
  for_each   = local.admin_users
  comment    = "Administrateur du cluster Proxmox"
  enabled    = true
  first_name = title(each.key)
  groups     = [proxmox_virtual_environment_group.admin.group_id]
  user_id    = "${each.key}@pam"
  lifecycle {
    ignore_changes  = [email, last_name, keys]
    prevent_destroy = true
  }
}
resource "proxmox_acl" "admin_administrator" {
  group_id  = "admin"
  path      = "/"
  propagate = true
  role_id   = "Administrator"
}
resource "proxmox_virtual_environment_group" "admin" {
  comment  = "Administrateurs du cluster Proxmox"
  group_id = "admin"
}

# ============================ #
# ========= OPENTOFU ========= #
# ============================ #
resource "proxmox_virtual_environment_user" "opentofu" {
  user_id = "opentofu@pve"
  comment = "OpenTofu provisionning (Administrator)"
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
# ==== COMPTES DE SERVICE ==== #
# ============================ #
locals {
  service_accounts = {
    packer = {
      comment = "Construction des templates Packer"
      role    = proxmox_virtual_environment_role.packer.role_id
    }
    ansible = {
      comment = "Ansible Inventory (read only)",
      role    = "PVEAuditor"
    }
    homarr = {
      comment = "Homarr Integration (read only)",
      role    = "PVEAuditor"
    }
    prometheus = {
      comment = "Exporter Prometheus (read only)",
      role    = "PVEAuditor"
    }
    pdm = {
      comment = "Proxmox Datacenter Manager (read only)",
      role    = "PVEAuditor"
    }
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

# ============================ #
# ========== TOKENS ========== #
# ============================ #
locals {
  managed_tokens = {
    packer = {
      user_id = proxmox_virtual_environment_user.service["packer"].user_id
      comment = "Construction des templates Packer"
      version = 2
    }
    ansible = {
      user_id = proxmox_virtual_environment_user.service["ansible"].user_id
      comment = "Inventaire dynamique Ansible"
      version = 1
    }
  }
}
resource "proxmox_user_token" "managed" {
  for_each              = local.managed_tokens
  user_id               = each.value.user_id
  token_name            = each.key
  comment               = "${each.value.comment}, gere par OpenTofu"
  privileges_separation = false
}
resource "vault_kv_secret_v2" "managed_tokens" {
  for_each             = local.managed_tokens
  mount                = "secret"
  name                 = "${each.key}/proxmox-token"
  data_json_wo         = jsonencode({ token = split("=", proxmox_user_token.managed[each.key].value)[1] })
  data_json_wo_version = each.value.version
}

# ============================ #
# ======= CUSTOM ROLES ======= #
# ============================ #
resource "proxmox_virtual_environment_role" "packer" {
  role_id = "Packer"
  privileges = [
    "VM.Allocate", "VM.Audit", "VM.Console", "VM.PowerMgmt", "VM.GuestAgent.Audit", "VM.Config.CDROM", "VM.Config.CPU", "VM.Config.Cloudinit", "VM.Config.Disk", "VM.Config.HWType", "VM.Config.Memory", "VM.Config.Network", "VM.Config.Options", "Datastore.AllocateSpace", "Datastore.Audit", "SDN.Use",
  ]
}
