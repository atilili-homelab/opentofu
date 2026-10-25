resource "proxmox_backup_job" "daily" {
  enabled           = true
  fleecing          = { enabled = true, storage = "local" }
  id                = "backup-fe994cf5-5393"
  mode              = "snapshot"
  notes_template    = "{{guestname}}({{vmid}}) on {{node}}"
  notification_mode = "notification-system"
  prune_backups     = { "keep-all" = "1" }
  schedule          = "02:00"
  storage           = "nas-backup"
  vmid = concat(
    [for name, vm in var.vms : tostring(local.vms_resolved[name].vm_id) if vm.backup],
    [for name, lxc in var.lxcs : tostring(local.lxcs_resolved[name].lxc_id) if lxc.backup],
  )
}
