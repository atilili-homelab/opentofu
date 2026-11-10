locals {
  ha_resources = merge(
    { for name, vm in var.vms : name => {
      id             = "vm:${module.vms[name].vm_id}"
      state          = vm.ha
      auto_rebalance = vm.gpu_passthrough ? false : null
      gpu            = vm.gpu_passthrough
      traefik        = contains(vm.tags, "traefik")
      } if vm.ha != null
    },
    { for name, lxc in var.lxcs : name => {
      id             = "ct:${module.lxcs[name].lxc_id}"
      state          = lxc.ha
      auto_rebalance = null
      gpu            = false
      traefik        = false
    } if lxc.ha != null },
  )

  traefik_preferred = {
    for name, vm in var.vms : name => vm.target_node if contains(vm.tags, "traefik") && vm.ha != null
  }
}

resource "proxmox_haresource" "this" {
  for_each = local.ha_resources

  resource_id    = each.value.id
  state          = each.value.state
  auto_rebalance = each.value.auto_rebalance
  # Le failback migre a chaud, impossible en passthrough : il bouclerait en echecs
  failback     = each.value.gpu ? false : null
  max_restart  = 2
  max_relocate = 2
}

resource "proxmox_harule" "zfs_nodes" {
  rule    = "zfs-nodes"
  type    = "node-affinity"
  strict  = true
  comment = "Ressource HA limitee aux noeuds qui ont local-ZFS (replication)"

  nodes     = { for n in proxmox_storage_zfspool.local_zfs.nodes : n => null }
  resources = [for k, r in proxmox_haresource.this : r.resource_id if !local.ha_resources[k].gpu && !local.ha_resources[k].traefik]
}

# Une ressource ne peut etre que dans une seule regle node-affinity : les VMs GPU et Traefik sont exclues de zfs-nodes
resource "proxmox_harule" "link_meganode" {
  rule    = "link-meganode"
  type    = "node-affinity"
  strict  = true
  comment = "VMs avec iGPU : noeuds ayant le mapping PCI, meganode prefere"

  nodes     = { for m in proxmox_hardware_mapping_pci.gpu_intel.map : m.node => m.node == "meganode" ? 2 : 1 }
  resources = [for k, r in proxmox_haresource.this : r.resource_id if local.ha_resources[k].gpu]

  # zfs-nodes doit avoir lache les VMs GPU avant la creation, sinon PVE desactive la regle en conflit
  depends_on = [proxmox_harule.zfs_nodes]
}

resource "proxmox_harule" "traefik_spread" {
  for_each = local.traefik_preferred

  rule    = "traefik-${each.key}"
  type    = "node-affinity"
  strict  = true
  comment = "Traefik ${each.key} : noeuds avec local-ZFS, ${each.value} prefere pour repartir la paire"

  nodes     = { for n in proxmox_storage_zfspool.local_zfs.nodes : n => n == each.value ? 2 : 1 }
  resources = [proxmox_haresource.this[each.key].resource_id]

  depends_on = [proxmox_harule.zfs_nodes]

  lifecycle {
    precondition {
      condition     = contains(proxmox_storage_zfspool.local_zfs.nodes, each.value)
      error_message = "Le target_node de ${each.key} doit avoir du ZFS local (replication)"
    }
  }
}
