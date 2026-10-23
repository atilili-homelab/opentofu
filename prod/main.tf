locals {
  vms_resolved = {
    for name, vm in var.vms : name => merge(vm, {
      ip_address = format("%s.%d.%d", var.ip_base, local.env.net_segment, vm.host_id)
      vm_id      = tonumber(format("%d%02d", local.env.net_segment, vm.host_id))
    })
  }
  lxcs_resolved = {
    for name, lxc in var.lxcs : name => merge(lxc, {
      ip_address = format("%s.%d.%d", var.ip_base, local.env.net_segment, lxc.host_id)
      lxc_id     = tonumber(format("%d%02d", local.env.net_segment, lxc.host_id))
    })
  }
}

locals {
  env_config = {
    lab = {
      net_segment    = 40
      vm_name_prefix = "lab-"
    }
    prod = {
      net_segment    = 30
      vm_name_prefix = ""
    }
  }
}

locals {
  env              = local.env_config[var.environment]
  gateway          = "${var.ip_base}.${local.env.net_segment}.1"
  shared_datastore = "nas-ressources"
}

locals {
  gpu_nodes = distinct([
    for name, vm in var.vms : vm.target_node
    if vm.gpu_passthrough
  ])
}

data "proxmox_hardware_pci" "gpu_check" {
  for_each  = toset(local.gpu_nodes)
  node_name = each.value
}

resource "proxmox_node_config" "nodes" {
  for_each    = toset(["meganode", "supernode", "mininode"])
  node_name   = each.value
  description = "Managed by OpenTofu"
}

module "vms" {
  source = "../modules/proxmox-vm"

  for_each = var.vms
  # Obligatoires
  target_node = each.value.target_node
  ip_address  = local.vms_resolved[each.key].ip_address
  vm_id       = local.vms_resolved[each.key].vm_id

  # Optionnels avec valeurs par défaut
  vm_name         = "${local.env.vm_name_prefix}${each.key}"
  gateway         = local.gateway
  cores           = each.value.cores
  cpu_shares      = each.value.cpu_shares
  memory          = each.value.memory
  memory_max      = each.value.memory_max
  disks           = each.value.disks
  gpu_passthrough = each.value.gpu_passthrough
  iso_file_id     = each.value.iso_file_id
  started         = each.value.started
  order           = each.value.order
  up_delay        = each.value.up_delay
  down_delay      = each.value.down_delay
  onboot          = each.value.onboot
  tags            = each.value.tags
  description = templatefile("${path.module}/vm-description.md.tftpl", {
    vm_name     = "${local.env.vm_name_prefix}${each.key}"
    description = each.value.description
    environment = var.environment
    ip_address  = local.vms_resolved[each.key].ip_address
    vm_id       = local.vms_resolved[each.key].vm_id
    target_node = each.value.target_node
    vlan        = local.env.net_segment
    cores       = each.value.cores
    cpu_shares  = each.value.cpu_shares
    memory      = each.value.memory
    memory_max  = each.value.memory_max != null ? each.value.memory_max : ""
    gpu         = each.value.gpu_passthrough ? "Passthrough activé" : "Non"
    onboot      = each.value.onboot ? "Oui" : "Non"
    tags        = join(", ", each.value.tags)
  })

  # Cloud-init commun pour toutes les VMs avec template
  cloud_init_user_data    = file("${path.module}/cloud-init-common.yaml")
  cloud_init_datastore_id = local.shared_datastore
  snippets_datastore_id   = local.shared_datastore
}

module "lxcs" {
  source = "../modules/proxmox-lxc"

  for_each = var.lxcs
  # Obligatoires
  target_node      = each.value.target_node
  ip_address       = local.lxcs_resolved[each.key].ip_address
  lxc_id           = local.lxcs_resolved[each.key].lxc_id
  lxc_name         = "${local.env.vm_name_prefix}${each.key}"
  gateway          = local.gateway
  template_file_id = each.value.template_file_id
  cores            = each.value.cores
  memory           = each.value.memory
  swap             = each.value.swap
  disk_size        = each.value.disk_size
  disk_datastore   = each.value.disk_datastore
  start_on_boot    = each.value.start_on_boot
  started          = each.value.started
  order            = each.value.order
  up_delay         = each.value.up_delay
  down_delay       = each.value.down_delay
  unprivileged     = each.value.unprivileged
  tags             = each.value.tags
  description = templatefile("${path.module}/lxc-description.md.tftpl", {
    lxc_name       = "${local.env.vm_name_prefix}${each.key}"
    description    = each.value.description
    environment    = var.environment
    ip_address     = local.lxcs_resolved[each.key].ip_address
    lxc_id         = local.lxcs_resolved[each.key].lxc_id
    target_node    = each.value.target_node
    vlan           = local.env.net_segment
    cores          = each.value.cores
    memory         = each.value.memory
    swap           = each.value.swap
    disk_size      = each.value.disk_size
    disk_datastore = each.value.disk_datastore
    unprivileged   = each.value.unprivileged ? "Oui" : "Non"
    start_on_boot  = each.value.start_on_boot ? "Oui" : "Non"
    tags           = join(", ", each.value.tags)
  })
  ssh_public_keys = var.ssh_public_keys
  password        = each.value.password
}

module "dns_records" {
  source = "../modules/technitium-dns"
  count  = var.environment == "prod" ? 1 : 0

  api_url           = "http://10.86.30.42:5380"
  token             = ephemeral.vault_kv_secret_v2.technitium.data["token"]
  vault_addr        = "http://sati.macopla.home:8200"
  vault_secret_path = "secret/data/opentofu/technitium"
  records = merge(
    { for name, _ in var.vms : "${local.env.vm_name_prefix}${name}" =>
    local.vms_resolved[name].ip_address },
    { for name, _ in var.lxcs : "${local.env.vm_name_prefix}${name}" =>
    local.lxcs_resolved[name].ip_address }
  )
}
