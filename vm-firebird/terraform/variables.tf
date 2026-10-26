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
  default = 20001
}

variable "vm_name" {
  type    = string
  default = "f99-db"
}

# Сдвиг нумерации: при 4 уже существующих db-серверах ставим 4 -> f99-db05
variable "name_offset" {
  type    = number
  default = 0
}

variable "vm_cores" {
  type    = number
  default = 4
}

variable "vm_memory" {
  type    = number
  default = 8192
}

# Системный диск, ГБ
variable "vm_disk_size" {
  type    = number
  default = 32
}

# Диск под swap, ГБ
variable "swap_disk_size" {
  type    = number
  default = 5
}

# Диск под базы (/mnt/db), ГБ
variable "data_disk_size" {
  type    = number
  default = 750
}

variable "storage_pool" {
  type    = string
  default = "zfs-ssd"
}

# Отдельный пул под диск с базами (пусто = storage_pool)
variable "data_storage_pool" {
  type    = string
  default = null
}

variable "vm_tags" {
  type    = list(string)
  default = ["deb", "db", "firebird"]
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
