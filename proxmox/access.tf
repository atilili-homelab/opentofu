resource "proxmox_virtual_environment_role" "packer" {
  role_id = "Packer"
  privileges = [
    "VM.Allocate", "VM.Audit", "VM.Console", "VM.PowerMgmt", "VM.GuestAgent.Audit", "VM.Config.CDROM", "VM.Config.CPU", "VM.Config.Cloudinit", "VM.Config.Disk", "VM.Config.HWType", "VM.Config.Memory", "VM.Config.Network", "VM.Config.Options", "Datastore.AllocateSpace", "Datastore.Audit", "SDN.Use",
  ]
}

resource "proxmox_virtual_environment_user" "packer" {
  user_id = "packer@pve"
  comment = "Construction des templates Packer"
  enabled = true
}

resource "proxmox_acl" "packer" {
  path      = "/"
  role_id   = proxmox_virtual_environment_role.packer.role_id
  user_id   = proxmox_virtual_environment_user.packer.user_id
  propagate = true
}

resource "proxmox_user_token" "packer" {
  user_id               = proxmox_virtual_environment_user.packer.user_id
  token_name            = "packer"
  comment               = "Token Packer, gere par OpenTofu"
  privileges_separation = false
}

resource "vault_kv_secret_v2" "packer_token" {
  mount = "secret"
  name  = "packer/proxmox-token"

  data_json_wo         = jsonencode({ token = split("=", proxmox_user_token.packer.value)[1] })
  data_json_wo_version = 2
}

# ==========
resource "proxmox_acl" "ansible_auditor" {
  group_id  = null
  path      = "/"
  propagate = true
  role_id   = "PVEAuditor"
  token_id  = null
  user_id   = "ansible@pve"
}

# __generated__ by OpenTofu from "/?admin?Administrator"
resource "proxmox_acl" "admin_administrator" {
  group_id  = "admin"
  path      = "/"
  propagate = true
  role_id   = "Administrator"
  token_id  = null
  user_id   = null
}

# __generated__ by OpenTofu from "/?prometheus@pve?PVEAuditor"
resource "proxmox_acl" "prometheus_auditor" {
  group_id  = null
  path      = "/"
  propagate = true
  role_id   = "PVEAuditor"
  token_id  = null
  user_id   = "prometheus@pve"
}

# __generated__ by OpenTofu from "ansible@pve"
resource "proxmox_virtual_environment_user" "ansible" {
  comment         = ""
  email           = ""
  enabled         = true
  expiration_date = "1970-01-01T00:00:00Z"
  first_name      = ""
  groups          = []
  keys            = ""
  last_name       = ""
  password        = null # sensitive
  user_id         = "ansible@pve"
}

# __generated__ by OpenTofu from "admin"
resource "proxmox_virtual_environment_group" "admin" {
  comment  = ""
  group_id = "admin"
}

# __generated__ by OpenTofu from "homarr@pve"
resource "proxmox_virtual_environment_user" "homarr" {
  comment         = "API Token Homarr Integration"
  email           = ""
  enabled         = true
  expiration_date = "1970-01-01T00:00:00Z"
  first_name      = ""
  groups          = []
  keys            = ""
  last_name       = ""
  password        = null # sensitive
  user_id         = "homarr@pve"
}

# __generated__ by OpenTofu from "/?homarr@pve?PVEAuditor"
resource "proxmox_acl" "homarr_auditor" {
  group_id  = null
  path      = "/"
  propagate = true
  role_id   = "PVEAuditor"
  token_id  = null
  user_id   = "homarr@pve"
}

# __generated__ by OpenTofu from "prometheus@pve"
resource "proxmox_virtual_environment_user" "prometheus" {
  comment         = "Exporter Prometheus read only"
  email           = ""
  enabled         = true
  expiration_date = "1970-01-01T00:00:00Z"
  first_name      = ""
  groups          = []
  keys            = ""
  last_name       = ""
  password        = null # sensitive
  user_id         = "prometheus@pve"
}
