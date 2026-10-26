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
