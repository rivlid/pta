variable "proxmox_url" {
  type    = string
  default = "https://192.168.0.12:8006/api2/json"
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
  default = "f99-hv14"
}