# Outputs dynamiques pour toutes les VMs
output "vm_ids" {
  description = "IDs des VMs créées"
  value       = { for name, vm in module.vms : name => vm.vm_id }
}
output "vm_ips" {
  description = "IPs des VMs créées"
  value       = { for name, vm in module.vms : name => vm.ip_address }
}
output "lxc_ids" {
  description = "IDs des LXC créés"
  value       = { for name, lxc in module.lxcs : name => lxc.lxc_id }
}
output "lxc_ips" {
  description = "IPs des LXC créés"
  value       = { for name, lxc in module.lxcs : name => lxc.ip_address }
}
