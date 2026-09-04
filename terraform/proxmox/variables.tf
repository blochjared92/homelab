variable "proxmox_endpoint" {
  description = "Base URL of the Proxmox VE API."
  type        = string
}

variable "proxmox_node" {
  description = "Name of the Proxmox node resources are created on."
  type        = string
}

variable "vm_ssh_public_key" {
  description = "Path to the public key injected into new VMs."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "lb_ip_lan" {
  description = "lb-01 address on the home network."
  type        = string
  default     = "10.0.0.220"
}

variable "lb_ip_cluster" {
  description = "lb-01 address on the isolated cluster network."
  type        = string
  default     = "10.31.100.1"
}

variable "cluster_name" {
  type    = string
  default = "ocp"
}

variable "base_domain" {
  type    = string
  default = "home.lab"
}

variable "test_vms" {
  description = "VMs to create, keyed by name."
  type = map(object({
    ip = string
  }))
  default = {}
}

variable "sno_ip" {
  description = "Address of the single-node OKD cluster."
  type        = string
  default     = "10.31.100.10"
}
