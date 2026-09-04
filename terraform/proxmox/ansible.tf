resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../../ansible/inventory.yml"
  file_permission = "0644"

  content = yamlencode({
    all = {
      children = {
        test_vms = {
          hosts = {
            for name, vm in var.test_vms : name => {
              ansible_host = vm.ip
            }
          }
          vars = {
            ansible_user               = "jared"
            ansible_python_interpreter = "/usr/bin/python3"
          }
        }
        loadbalancer = {
          hosts = {
            "lb-01" = {
              ansible_host = var.lb_ip_lan
            }
          }
          vars = {
            ansible_user               = "jared"
            ansible_python_interpreter = "/usr/bin/python3"
            cluster_name               = var.cluster_name
            base_domain                = var.base_domain
            lb_ip_cluster              = var.lb_ip_cluster
          }
        }
      }
    }
  })
}
