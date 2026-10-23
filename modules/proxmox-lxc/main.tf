#=============================================================#
#====================== CALCULS  LOCAUX ======================#
#=============================================================#

locals {
  # Construction du LXC ID depuis l'IP
  ip_parts = split(".", var.ip_address)
  lxc_id   = var.lxc_id != null ? var.lxc_id : tonumber("${local.ip_parts[2]}${local.ip_parts[3]}")

  # Détection VLAN avec IP (3e octet)
  network_segment = tonumber(local.ip_parts[2])
  # Attribution VLAN auto :
  # - Si IP en 10.86.30.x (même subnet que Proxmox) → pas de tag (0)
  # - Sinon (40, 99, etc.) → tag avec le segment réseau
  vlan_id = var.vlan_id != null ? var.vlan_id : (
    local.network_segment == 30 ? 0 : local.network_segment
  )

  hostname = coalesce(var.hostname, var.lxc_name)
}

#=============================================================#
#========================= BUILD  LXC ========================#
#=============================================================#

resource "proxmox_virtual_environment_container" "lxc" {
  node_name      = var.target_node
  vm_id          = local.lxc_id
  description    = var.description
  tags           = var.tags
  started        = var.started
  start_on_boot  = var.start_on_boot
  unprivileged   = var.unprivileged
  protection     = false
  timeout_delete = var.timeout_delete

  features {
    nesting = true
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = var.disk_datastore
    size         = var.disk_size
  }

  network_interface {
    name    = "eth0"
    bridge  = "vmbr0"
    vlan_id = local.vlan_id
  }

  dynamic "startup" {
    for_each = var.order != null ? [1] : []
    content {
      down_delay = var.down_delay
      order      = var.order
      up_delay   = var.up_delay
    }
  }

  initialization {
    hostname = local.hostname

    dns {
      domain  = var.domain
      servers = [var.gateway]
    }

    ip_config {
      ipv4 {
        address = "${var.ip_address}/${var.subnet_mask}"
        gateway = var.gateway
      }
    }

    user_account {
      keys     = var.ssh_public_keys
      password = var.password
    }
  }
}
