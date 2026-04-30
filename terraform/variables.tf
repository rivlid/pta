variable "proxmox_endpoint" {
  type    = string
  default = "https://192.168.0.12:8006/"
}

variable "proxmox_node" {
  type    = string
  default = "f99-hv14"
}

#variable "proxmox_api_token" {
#  type      = string
#  sensitive = true
#}

variable "proxmox_username" {
  type    = string
  default = "root@pam"
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "vm_count" {
  type    = number
  default = 1
}