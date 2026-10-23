#=============================================================#
#====================== CALCULS  LOCAUX ======================#
#=============================================================#

locals {
  # Construction du VM ID depuis l'IP
  ip_parts = split(".", var.ip_address)
  vm_id    = var.vm_id != null ? var.vm_id : tonumber("${local.ip_parts[2]}${local.ip_parts[3]}")

  # Détection VLAN avec IP (3e octet)
  network_segment = tonumber(local.ip_parts[2])

  # Attribution VLAN auto :
  # - Si IP en 10.86.30.x (même subnet que Proxmox) → pas de tag (0)
  # - Sinon (40, 99, etc.) → tag avec le segment réseau
  vlan_id = var.vlan_id != null ? var.vlan_id : (
    local.network_segment == 30 ? 0 : local.network_segment
  )

  #ISO Mode : si iso_file_id est défini, la VM est créé depuis l'ISO au lieu de cloner un template
  iso_mode = var.iso_file_id != null

  # Template ID ciblé selon le node de deploiement cible
  template_map = {
    meganode  = 9000
    supernode = 9001
    mininode  = 9002
  }
  template_id = var.template_id != null ? var.template_id : lookup(local.template_map, var.target_node, null)

  # Ordre des blocs disk piloté par l'interface (scsi2 avant scsi10), pas par le nom de clé
  disks_ordered = {
    for k, d in var.disks :
    format("%s%03d", regex("^[a-z]+", d.interface), tonumber(regex("[0-9]+$", d.interface))) => d
  }

  # Si le hostname de la VM est non défini, fallback sur vm_name
  hostname = coalesce(var.hostname, var.vm_name)
  fqdn     = "${local.hostname}.${var.domain}"

  # Construction du cloud-init final :
  # Préfixe le YAML utilisateur avec #cloud-config + hostname/fqdn/dns
  user_data = join("\n", [
    "#cloud-config",
    "hostname: ${local.hostname}",
    "fqdn: ${local.fqdn}",
    "manage_resolv_conf: true",
    "resolv_conf:",
    "  nameservers:",
    "    - ${var.gateway}",
    "  searchdomains:",
    "    - ${var.domain}",
    var.cloud_init_user_data
  ])
}

#=============================================================#
#================ BUILD  CLOUD-INIT  SNIPPETS ================#
#=============================================================#

resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  count        = local.iso_mode ? 0 : 1
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.target_node

  source_raw {
    data      = local.user_data
    file_name = "cloud-init-${var.vm_name}.yml"
  }
}

#=============================================================#
#========================= BUILD  VM =========================#
#=============================================================#

resource "proxmox_virtual_environment_vm" "vm" {
  name            = var.vm_name
  vm_id           = local.vm_id
  description     = var.description
  tags            = var.tags
  node_name       = var.target_node
  on_boot         = var.onboot
  keyboard_layout = "fr"
  machine         = var.gpu_passthrough ? "q35" : null
  stop_on_destroy = true
  started         = var.started
  dynamic "startup" {
    for_each = var.order != null ? [1] : []
    content {
      down_delay = var.down_delay
      order      = var.order
      up_delay   = var.up_delay
    }
  }
  protection    = false
  scsi_hardware = "virtio-scsi-single"
  lifecycle {
    ignore_changes = [clone]
  }
  agent {
    enabled = true #qemu-guest-agent
    trim    = true
  }
  dynamic "clone" {
    for_each = local.iso_mode ? [] : [1]
    content {
      vm_id = local.template_id
    }
  }
  cpu {
    cores = var.cores
    type  = var.cpu_type
    units = var.cpu_shares
  }
  # ISO : monter le fichier ISO comme lecteur CD virtuel
  dynamic "cdrom" {
    for_each = local.iso_mode ? [1] : []
    content {
      file_id   = var.iso_file_id
      interface = "ide2"
    }
  }
  # GPU Passthrough (Yoflix)
  dynamic "hostpci" {
    for_each = var.gpu_passthrough ? [1] : []
    content {
      device  = "hostpci0"
      mapping = var.gpu_mapping
      pcie    = var.gpu_pcie
      rombar  = var.gpu_rombar
      xvga    = false # Pas de VGA primaire (garde le VGA virtuel pour boot)
    }
  }
  memory {
    dedicated = var.memory_max != null ? var.memory_max : var.memory
    floating  = var.memory_max != null ? var.memory : var.memory
  }
  network_device {
    model   = "virtio"
    bridge  = "vmbr0"
    vlan_id = local.vlan_id
  }
  dynamic "disk" {
    for_each = local.disks_ordered
    content {
      interface    = disk.value.interface
      size         = disk.value.size
      datastore_id = disk.value.storage
      aio          = disk.value.aio
      iothread     = disk.value.iothread
      backup       = disk.value.backup
      cache        = disk.value.cache
      discard      = disk.value.discard
      replicate    = disk.value.replicate
      ssd          = disk.value.ssd
    }
  }
  dynamic "initialization" {
    for_each = local.iso_mode ? [] : [1]
    content {
      datastore_id      = var.cloud_init_datastore_id
      user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data[0].id
      upgrade           = true
      ip_config {
        ipv4 {
          address = "${var.ip_address}/${var.subnet_mask}"
          gateway = var.gateway
        }
      }
      dns {
        domain  = var.domain
        servers = [var.gateway]
      }
    }
  }
}

# Un diff sur cette ressource au plan = l'apply va rebooter la VM
resource "terraform_data" "reboot_expected" {
  input = {
    cores      = var.cores
    cpu_type   = var.cpu_type
    cpu_shares = var.cpu_shares
    memory     = var.memory
    memory_max = var.memory_max
    gpu        = var.gpu_passthrough ? [var.gpu_mapping, var.gpu_pcie, var.gpu_rombar] : null
    network = local.iso_mode ? null : {
      ip      = "${var.ip_address}/${var.subnet_mask}"
      gateway = var.gateway
      domain  = var.domain
    }
    disks = { for d in values(var.disks) : d.interface => {
      storage = d.storage
      aio     = d.aio
    } }
  }

  depends_on = [proxmox_virtual_environment_vm.vm]
}
