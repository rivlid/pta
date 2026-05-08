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
  vm_id     = var.vm_id
  name      = var.vm_name
  node_name = var.proxmox_node
  tags      = var.vm_tags

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
    datastore_id = var.storage_pool
    size         = 20
    interface    = "scsi0"
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
    vlan_id  = var.vlan_id
  }

  agent {
    enabled = true  # qemu-guest-agent
  }

  initialization {
    datastore_id = var.storage_pool
    dns {
        servers = var.dns_servers
        domain = var.dns_domain
    }
    ip_config {
      ipv4 {
        address = var.dhcp ? "dhcp" : var.ip_address
        gateway = var.dhcp ? null : var.ip_gateway
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