locals {
  zfs_nodes = proxmox_storage_zfspool.local_zfs.nodes

  replications = merge(
    {
      for name, vm in var.vms : name => {
        id     = "${local.vms_resolved[name].vm_id}-0"
        target = one([for n in local.zfs_nodes : n if n != vm.target_node])
      }
      if vm.replicate
    },
    {
      for name, lxc in var.lxcs : name => {
        id     = "${local.lxcs_resolved[name].lxc_id}-0"
        target = one([for n in local.zfs_nodes : n if n != lxc.target_node])
      }
      if lxc.replicate
    },
  )
}

resource "proxmox_replication" "this" {
  for_each = local.replications

  id     = each.value.id
  target = each.value.target
  type   = "local"

  lifecycle {
    # Proxmox inverse la tache quand la VM migre vers sa cible
    ignore_changes = [target]
  }
}

import {
  for_each = {
    for name, r in local.replications : name => r
    if contains(["3031-0", "3032-0", "3033-0", "3041-0", "3051-0", "3053-0"], r.id)
  }
  to = proxmox_replication.this[each.key]
  id = each.value.id
}
