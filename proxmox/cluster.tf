resource "proxmox_cluster_options" "this" {
  console                   = "vv"
  crs_ha                    = "dynamic"
  crs_ha_auto_rebalance     = true
  crs_ha_rebalance_on_start = true
  email_from                = "admin@macopla.com"
  ha_shutdown_policy        = "migrate"
  keyboard                  = "fr"
  mac_prefix                = "BC:24:11"
  migration_cidr            = "10.86.80.1/24"
  migration_type            = "insecure"
}

resource "proxmox_hardware_mapping_pci" "gpu_intel" {
  comment = "iGPU Intel Iris Xe (Alder Lake-P), transcodage Jellyfin"
  map = [
    {
      id           = "8086:46a6"
      iommu_group  = 0
      node         = "meganode"
      path         = "0000:00:02.0"
      subsystem_id = "8086:2212"
    },
    {
      id           = "8086:46a6"
      iommu_group  = 0
      node         = "supernode"
      path         = "0000:00:02.0"
      subsystem_id = "0000:0000"
    },
  ]
  mediated_devices = false
  name             = "gpu-intel"
}
