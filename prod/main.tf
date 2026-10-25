locals {
  vms_resolved = {
    for name, vm in var.vms : name => merge(vm, {
      ip_address = format("%s.%d.%d", var.ip_base, local.net_segment, vm.host_id)
      vm_id      = tonumber(format("%d%02d", local.net_segment, vm.host_id))
    })
  }
  lxcs_resolved = {
    for name, lxc in var.lxcs : name => merge(lxc, {
      ip_address = format("%s.%d.%d", var.ip_base, local.net_segment, lxc.host_id)
      lxc_id     = tonumber(format("%d%02d", local.net_segment, lxc.host_id))
    })
  }
}

locals {
  net_segment      = 30
  gateway          = "${var.ip_base}.${local.net_segment}.1"
  shared_datastore = "nas-ressources"
}

locals {
  dns_records = merge(
    { for name, _ in var.vms : name => local.vms_resolved[name].ip_address },
    { for name, _ in var.lxcs : name => local.lxcs_resolved[name].ip_address }
  )
}

resource "proxmox_node_config" "nodes" {
  for_each    = var.nodes
  node_name   = each.key
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
  vm_name         = each.key
  gateway         = local.gateway
  cores           = each.value.cores
  cpu_shares      = each.value.cpu_shares
  memory          = each.value.memory
  memory_max      = each.value.memory_max
  disks           = each.value.disks
  gpu_passthrough = each.value.gpu_passthrough
  iso_file_id     = each.value.iso_file_id
  started         = each.value.started
  protection      = each.value.protection
  order           = each.value.order
  up_delay        = each.value.up_delay
  down_delay      = each.value.down_delay
  onboot          = each.value.onboot
  tags            = each.value.tags
  template_id     = var.nodes[each.value.target_node].template_id
  description = templatefile("${path.module}/vm-description.md.tftpl", {
    vm_name     = each.key
    description = each.value.description
    ip_address  = local.vms_resolved[each.key].ip_address
    vm_id       = local.vms_resolved[each.key].vm_id
    target_node = each.value.target_node
    vlan        = local.net_segment
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
  lxc_name         = each.key
  gateway          = local.gateway
  template_file_id = each.value.template_file_id
  cores            = each.value.cores
  memory           = each.value.memory
  swap             = each.value.swap
  disk_size        = each.value.disk_size
  disk_datastore   = each.value.disk_datastore
  start_on_boot    = each.value.start_on_boot
  started          = each.value.started
  protection       = each.value.protection
  order            = each.value.order
  up_delay         = each.value.up_delay
  down_delay       = each.value.down_delay
  unprivileged     = each.value.unprivileged
  tags             = each.value.tags
  description = templatefile("${path.module}/lxc-description.md.tftpl", {
    lxc_name       = each.key
    description    = each.value.description
    ip_address     = local.lxcs_resolved[each.key].ip_address
    lxc_id         = local.lxcs_resolved[each.key].lxc_id
    target_node    = each.value.target_node
    vlan           = local.net_segment
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
  source  = "../modules/dns-records"
  records = local.dns_records
}

moved {
  from = module.dns_records[0]
  to   = module.dns_records
}
