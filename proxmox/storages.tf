import {
  to = proxmox_storage_pbs.nas_backup
  id = "nas-backup"
}

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
  fingerprint = "af:54:0c:e6:eb:64:ce:aa:17:51:7c:ad:77:90:30:45:0b:8e:d8:b4:69:ca:cf:70:05:d8:f8:7a:6b:3f:06:e6"
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
