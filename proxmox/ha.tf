locals {
  ha_resources = merge(
    { for name, vm in var.vms : name => {
      id             = "vm:${local.vms_resolved[name].vm_id}"
      state          = vm.ha
      auto_rebalance = vm.gpu_passthrough ? false : null
      } if vm.ha != null
    },
    { for name, lxc in var.lxcs : name => {
      id             = "ct:${local.lxcs_resolved[name].lxc_id}"
      state          = lxc.ha
      auto_rebalance = null
    } if lxc.ha != null },
  )
}

resource "proxmox_haresource" "this" {
  for_each = local.ha_resources

  resource_id    = each.value.id
  state          = each.value.state
  auto_rebalance = each.value.auto_rebalance
  max_restart    = 2
  max_relocate   = 2
}

resource "proxmox_harule" "zfs_nodes" {
  rule    = "zfs-nodes"
  type    = "node-affinity"
  strict  = true
  comment = "Ressource HA limitee aux noeuds qui ont local-ZFS (replication)"

  nodes     = { for n in proxmox_storage_zfspool.local_zfs.nodes : n => null }
  resources = [for r in proxmox_haresource.this : r.resource_id]
}
