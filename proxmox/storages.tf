resource "proxmox_storage_lvm" "local_lvm2" {
  content              = ["images", "rootdir"]
  disable              = false
  id                   = "local-LVM2"
  nodes                = ["mininode"]
  shared               = false
  volume_group         = "local-LVM2"
  wipe_removed_volumes = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_storage_zfspool" "local_zfs" {
  content        = ["images", "rootdir"]
  disable        = false
  id             = "local-ZFS"
  nodes          = ["meganode", "supernode"]
  thin_provision = true
  zfs_pool       = "rpool"

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_storage_nfs" "nas_ressources" {
  content          = ["backup", "images", "import", "iso", "rootdir", "snippets", "vztmpl"]
  create_base_path = true
  create_subdirs   = true
  disable          = false
  export           = "/mnt/tank/proxmox-ressources"
  id               = "nas-ressources"
  nodes            = []
  server           = "10.86.30.100"

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_storage_lvm" "local_lvm" {
  content              = ["images", "rootdir"]
  disable              = false
  id                   = "local-LVM"
  nodes                = ["mininode"]
  shared               = false
  volume_group         = "pve"
  wipe_removed_volumes = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_storage_directory" "local" {
  content          = ["images", "snippets"]
  create_base_path = true
  create_subdirs   = true
  disable          = false
  id               = "local"
  nodes            = []
  path             = "/var/lib/vz"
  shared           = false

  lifecycle {
    prevent_destroy = true
  }
}

# TODO: switch to vault_kv_secret_v2 when [#2960](https://github.com/bpg/terraform-provider-proxmox/pull/2960) is resolved

data "vault_generic_secret" "pbs" {
  path = "secret/opentofu/backup-agent"
}

resource "proxmox_storage_pbs" "nas_backup" {
  content     = ["backup"]
  datastore   = "storenas"
  disable     = false
  fingerprint = "22:42:e2:51:0a:64:70:bf:30:3b:20:67:08:1a:69:fa:3e:46:1a:e4:5f:34:2d:fa:ed:b0:e3:3c:47:e5:61:6b"
  id          = "nas-backup"
  namespace   = "Macopla"
  nodes       = []
  password    = data.vault_generic_secret.pbs.data["password"]
  server      = "10.86.30.110"
  username    = "backup-agent@pbs"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [password]
  }
}
