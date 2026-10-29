# ============================================================
# TEMPLATE DE LXC - Copier/coller et modifier les valeurs
# ============================================================
/*
  "NOM-DU-LXC" = {
    target_node = "meganode"    # meganode / supernode / mininode
    host_id     = XX            # 20-99, unique VM + LXC : dernier octet IP + base du VMID

    # Optionnel (valeurs par défaut)
    template_file_id = "nas-ressources:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    cores            = 1
    memory           = 512
    swap             = 0
    disk_size        = 4
    disk_datastore   = "local-ZFS"
    unprivileged     = true
    ssh_public_keys  = []
    password         = null
    started          = true
    start_on_boot    = true
    order            = null
    up_delay         = null
    down_delay       = null
    protection       = true
    backup           = false    # Job quotidien
    ha               = null     # started / stopped / ignored / disabled
    replicate        = false    # Réplication ZFS vers l'autre nœud ZFS
    description      = null
    services         = []       # Un CNAME par nom, ex. ["bao"]
    tags             = []       # Groupes Ansible
  }
*/

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
    ha          = "started"
    replicate   = true
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
    ha          = "started"
    replicate   = true
    services    = ["bao"]
    tags        = ["openbao_server"]
  }
}
