variable "proxmox_endpoint" {
  type    = string
  default = "https://192.168.0.1:8006/"
}

variable "proxmox_username" {
  type    = string
  default = "root@pam"
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_nodes" {
  type    = list(string)
  default = ["f01-hv01"]
}

variable "vm_count" {
  type    = number
  default = 1
}

variable "vm_id" {
  type    = number
  default = 10001
}

variable "vm_name" {
  type    = string
  default = "employee"
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_memory" {
  type    = number
  default = 2048
}

variable "vm_disk_size" {
  type    = number
  default = 50
}

variable "storage_pool" {
  type    = string
  default = "zfs-ssd"
}

variable "vm_tags" {
  type    = list(string)
  default = ["employee", "deb"]
}

variable "vlan_id" {
  type    = string
  default = null
}

variable "dns_servers" {
  type    = list(string)
  default = ["192.168.9.4"]
}

variable "dns_domain" {
  type    = string
  default = "sadkomed.local"
}

variable "dhcp" {
  type    = bool
  default = true
}

variable "ip_address" {
  type    = string
  default = "192.168.9.100/24"
}

variable "ip_gateway" {
  type    = string
  default = null
}