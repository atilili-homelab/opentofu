output "vm_id" {
  value       = proxmox_virtual_environment_vm.vm.vm_id
  description = "ID de la VM créée"
}

output "vm_name" {
  value       = proxmox_virtual_environment_vm.vm.name
  description = "Nom de la VM"
}

output "ip_address" {
  value       = var.ip_address
  description = "Adresse IP de la VM"
}

output "fqdn" {
  value       = local.fqdn
  description = "FQDN de la VM"
}
