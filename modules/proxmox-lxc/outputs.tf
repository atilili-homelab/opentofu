output "lxc_id" {
  value       = proxmox_virtual_environment_container.lxc.vm_id
  description = "ID du conteneur LXC"
}

output "lxc_name" {
  value       = var.lxc_name
  description = "Nom du conteneur LXC"
}

output "ip_address" {
  value       = var.ip_address
  description = "Adresse IP du conteneur"
}
