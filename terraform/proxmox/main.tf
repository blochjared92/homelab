resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name    = "noble-server-cloudimg-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "test_vm" {
  for_each = var.test_vms

  name        = each.key
  description = "Created by Terraform. Safe to destroy."
  node_name   = var.proxmox_node
  tags        = ["terraform", "test"]

  stop_on_destroy = true

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    size         = 20
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.0.0.1"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config[each.key].id
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  for_each = var.test_vms

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    file_name = "${each.key}-cloud-config.yaml"

    data = <<-EOF
    #cloud-config
    hostname: ${each.key}
    users:
      - default
      - name: jared
        groups: [sudo]
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${trimspace(file(pathexpand(var.vm_ssh_public_key)))}
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable --now qemu-guest-agent
    EOF
  }
}

resource "proxmox_virtual_environment_download_file" "rocky_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://dl.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2"
  file_name    = "rocky-10-genericcloud.qcow2"
}

resource "proxmox_virtual_environment_file" "lb_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    file_name = "lb-01-cloud-config.yaml"

    data = <<-EOF
    #cloud-config
    hostname: lb-01.${var.cluster_name}.${var.base_domain}
    users:
      - default
      - name: jared
        groups: [wheel]
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${trimspace(file(pathexpand(var.vm_ssh_public_key)))}
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable --now qemu-guest-agent
    EOF
  }
}

resource "proxmox_virtual_environment_vm" "lb_01" {
  name        = "lb-01"
  description = "DNS, DHCP, and load balancer for the OCP cluster."
  node_name   = var.proxmox_node
  tags        = ["terraform", "cluster", "infra"]

  stop_on_destroy = true

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.rocky_cloud_image.id
    interface    = "scsi0"
    size         = 40
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.lb_ip_lan}/24"
        gateway = "10.0.0.1"
      }
    }

    ip_config {
      ipv4 {
        address = "${var.lb_ip_cluster}/24"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.lb_cloud_config.id
  }

  network_device {
    bridge = "vmbr0"
  }

  network_device {
    bridge = "vmbr1"
  }
}

resource "proxmox_virtual_environment_vm" "ocp1" {
  name        = "ocp1"
  description = "Single-node OKD cluster."
  node_name   = var.proxmox_node
  tags        = ["terraform", "okd"]

  stop_on_destroy = true

  agent {
    enabled = false
  }

  cpu {
    cores = 6
    type  = "host"
  }

  memory {
    dedicated = 20480
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 120
  }

  cdrom {
    file_id = "local:iso/scos-live.iso"
  }

  boot_order = ["scsi0", "ide3"]

  network_device {
    bridge = "vmbr1"
  }

}
