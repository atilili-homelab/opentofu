locals {
  ha_resources = merge(
    { for name, vm in var.vms : name => {
      id             = "vm:${local.vms_resolved[name].vm_id}"
      state          = vm.ha
      auto_rebalance = vm.gpu_passthrough ? false : null
      gpu            = vm.gpu_passthrough
      } if vm.ha != null
    },
    { for name, lxc in var.lxcs : name => {
      id             = "ct:${local.lxcs_resolved[name].lxc_id}"
      state          = lxc.ha
      auto_rebalance = null
      gpu            = false
    } if lxc.ha != null },
  )

  traefik_ha = [
    for name, vm in var.vms : proxmox_haresource.this[name].resource_id if contains(vm.tags, "traefik") && vm.ha != null
  ]
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
  resources = [for k, r in proxmox_haresource.this : r.resource_id if !local.ha_resources[k].gpu]
}

# Une ressource ne peut etre que dans une seule regle node-affinity : les VMs GPU sont exclues de zfs-nodes
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

resource "proxmox_harule" "traefik_apart" {
  rule     = "traefik-apart"
  type     = "resource-affinity"
  affinity = "negative"
  comment  = "Paire keepalived Traefik : jamais sur le meme noeud"

  resources = local.traefik_ha

  lifecycle {
    precondition {
      condition     = length(local.traefik_ha) <= length(proxmox_storage_zfspool.local_zfs.nodes)
      error_message = "Le nombre de noeuds avec ZFS local est insuffisant pour separer les instances Traefik"
    }
  }
}
