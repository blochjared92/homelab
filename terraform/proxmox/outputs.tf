output "test_vm_ips" {
  description = "Configured address for each test VM."
  value       = { for name, vm in var.test_vms : name => vm.ip }
}
output "test_vm_ip_list" {
  description = "Plain list of VM addresses, for scripting."
  value       = [for name, vm in var.test_vms : vm.ip]
}

output "lb_01_ips" {
  value = {
    lan     = var.lb_ip_lan
    cluster = var.lb_ip_cluster
  }
}
