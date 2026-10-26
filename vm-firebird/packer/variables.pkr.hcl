variable "proxmox_url" {
  type    = string
  default = "https://192.168.0.1:8006/api2/json"
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

variable "storage_pool" {
  type    = string
  default = "zfs-ssd"
}

# NFS-шара для бэкапов БД (пусто = не добавлять в fstab)
variable "backup_nfs_src" {
  type    = string
  default = "192.168.0.31:/data/backup/infodent"
}

variable "backup_mount" {
  type    = string
  default = "/mnt/backup"
}
