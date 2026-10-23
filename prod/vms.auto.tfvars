# ============================================================
# TEMPLATE DE VM - Copier/coller et modifier les valeurs
# ============================================================
/*
  "NOM-DE-LA-VM" = {
    target_node = "meganode"    # meganode / supernode / mininode
    host_id     = XX            # 20-99, dernier octet IP + base du VMID

    # Optionnel (valeurs par défaut)
    cores            = 1
    cpu_shares       = 1024     # 512 (low) / 1024 (normal) / 2048 (high)
    memory           = 2048
    memory_max       = null     # Activer ballooning si défini
    onboot           = true
    order            = null
    up_delay         = null
    down_delay       = null
    gpu_passthrough  = false
    started					 = true
    iso_file_id      = null     # Si défini, crée depuis ISO au lieu du template
    # Tags = groupes Ansible de base (générés dans l'inventaire dynamique)
    tags = ["prod", "swarm_workers"]
    disks = {
      root = { size = 10, storage = "local-ZFS" }
      data = { size = 50, storage = "local-ZFS", interface = "scsi1", backup = false }
    }
  }
*/
environment = "prod"

vms = {
  # =============================================================
  # SWARM MANAGERS (VMs légères, pas de disk data)
  # =============================================================
  "neo" = {
    target_node = "meganode"
    host_id     = 21
    cores       = 1
    memory      = 1024
    disks = {
      root = { size = 16 }
    }
    order      = 2
    up_delay   = 10
    down_delay = 10
    tags       = ["manager"]
  }
  "morpheus" = {
    target_node = "supernode"
    host_id     = 22
    cores       = 1
    memory      = 1024
    disks = {
      root = { size = 16 }
    }
    order      = 2
    up_delay   = 10
    down_delay = 10
    tags       = ["manager"]
  }
  "trinity" = {
    target_node = "mininode"
    host_id     = 23
    cores       = 1
    memory      = 1024
    disks = {
      root = { size = 16, storage = "local-LVM" }
    }
    order      = 2
    up_delay   = 10
    down_delay = 10
    tags       = ["manager"]
  }

  # =============================================================
  # SWARM WORKERS
  # =============================================================

  "seraph" = {
    target_node = "meganode"
    host_id     = 31
    cores       = 2
    cpu_shares  = 2048
    memory      = 5120
    disks = {
      root = { size = 32 }
      data = { size = 100, interface = "scsi1", backup = true }
    }
    order      = 3
    up_delay   = 10
    down_delay = 10
    tags       = ["tier_infra", "traefik"]
  }

  "niobe" = {
    target_node = "supernode"
    host_id     = 32
    cores       = 4
    cpu_shares  = 2048
    memory      = 4096
    disks = {
      root = { size = 32 }
      data = { size = 100, interface = "scsi1", backup = true }
    }
    order      = 3
    up_delay   = 10
    down_delay = 10
    tags       = ["tier_apps", "traefik"]
  }

  "link" = {
    target_node     = "meganode"
    host_id         = 33
    cores           = 8
    cpu_shares      = 2048
    memory          = 8192
    gpu_passthrough = true
    disks = {
      root = { size = 100, backup = true }
    }
    order      = 3
    up_delay   = 10
    down_delay = 10
    tags       = ["tier_media"]
  }

  "oracle" = {
    target_node = "mininode"
    host_id     = 34
    cores       = 2
    memory      = 4096
    disks = {
      root = { size = 32, backup = true, storage = "local-LVM" }
    }
    order      = 3
    up_delay   = 10
    down_delay = 10
    tags       = ["tier_monitor"]
  }

  "dozer" = {
    target_node = "meganode"
    host_id     = 35
    cores       = 2
    cpu_shares  = 1024
    memory      = 4096
    disks = {
      root = { size = 32, storage = "local-ZFS" }
      data = { size = 50, storage = "local-ZFS", interface = "scsi1", backup = true }
    }
    onboot     = true
    order      = 1
    up_delay   = 15
    down_delay = 15
    started    = true
    tags       = ["tier_database"]
  }

  # =============================================================
  # VMS STANDALONE (hors Swarm)
  # =============================================================

  "persephone" = {
    target_node = "supernode"
    host_id     = 53
    memory      = 4096
    disks = {
      root = { size = 32, storage = "local-ZFS" }
      data = { size = 100, storage = "local-ZFS", interface = "scsi1", backup = true }
    }
    order      = 3
    up_delay   = 10
    down_delay = 10
    tags       = ["mail", "tier_standalone"]
  }

  "merovingian" = {
    target_node = "supernode"
    host_id     = 51
    cores       = 2
    cpu_shares  = 512
    memory      = 2048
    disks = {
      root = { size = 32, storage = "local-ZFS" }
    }
    order      = 3
    up_delay   = 10
    down_delay = 10
    tags       = ["seedbox", "tier_standalone"]
  }


  "mouse" = {
    target_node = "supernode"
    host_id     = 52
    cores       = 6
    cpu_shares  = 512
    memory      = 8192
    disks = {
      root  = { size = 32 }
      store = { size = 100, storage = "local-ZFS", interface = "scsi1" }
    }
    tags = ["ci", "tier_standalone"]
  }

  "zion" = {
    target_node = "supernode"
    host_id     = 86
    cores       = 4
    cpu_shares  = 512
    memory      = 4096
    onboot      = false
    started     = false
    disks = {
      root = { size = 64 }
    }
    tags = ["capsule", "tier_standalone"]
  }
}
