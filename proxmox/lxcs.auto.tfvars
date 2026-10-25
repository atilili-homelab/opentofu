# ============================================================
# LXC Containers
# ============================================================

lxcs = {
  # =============================================================
  # DATABASE
  # =============================================================
  "tank" = {
    target_node = "meganode"
    host_id     = 41
    cores       = 2
    memory      = 2048
    disk_size   = 50
    order       = 1
    up_delay    = 10
    tags        = ["db_server"]
  }

  # =============================================================
  # DNS (Technitium, cluster 2 nœuds)
  # =============================================================
  "keymaker" = {
    target_node = "meganode"
    host_id     = 42
    cores       = 1
    memory      = 512
    disk_size   = 4
    order       = 1
    up_delay    = 10
    tags        = ["dns_server"]
  }
  "trainman" = {
    target_node = "supernode"
    host_id     = 43
    cores       = 1
    memory      = 512
    disk_size   = 4
    order       = 1
    up_delay    = 10
    tags        = ["dns_server"]
  }

  # =============================================================
  # Vault (OpenBao, gestion des secrets)
  # =============================================================
  "sati" = {
    target_node = "supernode"
    host_id     = 44
    cores       = 1
    memory      = 512
    disk_size   = 4
    order       = 2
    up_delay    = 10
    backup      = true
    tags        = ["openbao_server"]
  }
}
