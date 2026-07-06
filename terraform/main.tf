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

locals {
  ip_parts    = split("/", var.ip_address)
  ip_octets   = split(".", local.ip_parts[0])
  ip_prefix   = local.ip_parts[1]
  ip_network  = "${local.ip_octets[0]}.${local.ip_octets[1]}.${local.ip_octets[2]}.0/${local.ip_prefix}"
  ip_host_num = tonumber(local.ip_octets[3])
}

resource "proxmox_virtual_environment_vm" "debian" {
  count     = var.vm_count
  vm_id     = var.vm_id + count.index
  name      = "${var.vm_name}-${format("%02d", count.index + var.name_offset + 1)}"
  node_name = var.proxmox_node
  tags      = var.vm_tags

# Игнорирем изменения и ребут, ньанс с ключиками, если хотим сменить айпишники и прочее выключаем
  lifecycle {
    ignore_changes = [initialization]
  }

  clone {
    vm_id = 9000  # ID шаблона который создал Packer
    full  = true
  }

  cpu {
    cores = var.vm_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    datastore_id = var.storage_pool
    size         = var.vm_disk_size
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
        address = var.dhcp ? "dhcp" : "${cidrhost(local.ip_network, local.ip_host_num + count.index)}/${local.ip_prefix}"
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
  value = [for vm in proxmox_virtual_environment_vm.debian : {
    name = vm.name
    id   = vm.vm_id
    ip   = var.dhcp ? try(flatten(vm.ipv4_addresses)[1], "pending") : "${cidrhost(local.ip_network, local.ip_host_num + (vm.vm_id - var.vm_id))}/${local.ip_prefix}"
  }]
}