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

variable "proxmox_node" {
  type    = string
  default = "f01-hv01"
}

#variable "proxmox_api_token" {
#  type      = string
#  sensitive = true
#} 

variable "vm_count" {
  type    = number
  default = 1
}

variable "storage_pool" {
  type    = string
  default = "zfs-ssd"
}