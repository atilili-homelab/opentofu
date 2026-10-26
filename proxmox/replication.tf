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
