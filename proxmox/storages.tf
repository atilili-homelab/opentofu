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
