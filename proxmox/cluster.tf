import {
  to = proxmox_cluster_options.this
  id = "cluster"
}

resource "proxmox_cluster_options" "this" {
  bandwidth_limit_clone               = null
  bandwidth_limit_default             = null
  bandwidth_limit_migration           = null
  bandwidth_limit_move                = null
  bandwidth_limit_restore             = null
  console                             = "vv"
  crs_ha                              = null
  crs_ha_auto_rebalance               = null
  crs_ha_auto_rebalance_hold_duration = null
  crs_ha_auto_rebalance_margin        = null
  crs_ha_auto_rebalance_method        = null
  crs_ha_auto_rebalance_threshold     = null
  crs_ha_rebalance_on_start           = null
  description                         = null
  email_from                          = "admin@macopla.com"
  ha_shutdown_policy                  = "migrate"
  http_proxy                          = null
  keyboard                            = "fr"
  language                            = null
  mac_prefix                          = "BC:24:11"
  max_workers                         = null
  migration_cidr                      = "10.86.80.1/24"
  migration_type                      = "insecure"
  next_id                             = null
  notify                              = null
}
