terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  #api_token = var.proxmox_api_token
  username = var.proxmox_username
  password = var.proxmox_password
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "debian" {
  count     = var.vm_count
  name      = "debian-${count.index + 1}"
  node_name = var.proxmox_node

  clone {
    vm_id = 9000  # ID шаблона который создал Packer
    full  = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "zfs-ssd"
    size         = 20
    interface    = "scsi0"
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
    vlan_id  = 9
  }

  agent {
    enabled = true  # qemu-guest-agent
  }

  initialization {
    datastore_id = "zfs-ssd"
    dns {
        servers = ["192.168.9.4"]
        domain = "sadkomed.local"
    }
    ip_config {
      ipv4 {
        address = "192.168.9.85/24"
        gateway = "192.168.9.254"
      }
    }
    user_account {
      username = "root"
      keys     = [file("~/.ssh/id_rsa.pub")]
    }
  }
}

output "vm_ips" {
  value = [for vm in proxmox_virtual_environment_vm.debian : vm.name]
}