packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "debian13" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node    = var.proxmox_node
  vm_id   = 9000
  vm_name = "debian-13-template"
  boot_iso {
    iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso"
    iso_checksum     = "sha256:65273beed27b2df543b68b65630ba525cfbad8df2b12035732b2dff87d6664e7"
    iso_storage_pool = "local"
    unmount          = true
    }
  cores   = 2
  memory  = 2048
  sockets = 1

  scsi_controller = "virtio-scsi-single"

  disks {
    disk_size         = "20G"
    storage_pool      = var.storage_pool
    type              = "scsi"
    discard           = true
    io_thread         = true
  }

  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
    vlan_tag = 9
  }

  cloud_init              = true
  cloud_init_storage_pool = var.storage_pool

  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "hostname=debian locale=en_US.UTF-8 ",
    "keyboard-configuration/xkb-keymap=us ",
    "interface=auto ",
    "netcfg/get_hostname=debian netcfg/get_domain=local ",
    "<enter>"
  ]

  http_directory = "packer/http"

  ssh_username         = "root"
  ssh_password         = "debian"
  ssh_timeout          = "30m"
  ssh_handshake_attempts = 50

  template_name        = "debian-13-template"
  template_description = "Debian 13 - Cloud Init"
  unmount_iso          = true
}

build {
  sources = ["source.proxmox-iso.debian13"]

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y cloud-init qemu-guest-agent curl wget locales systemd-resolved netplan.io",
      # Локали
      "sed -i 's/# ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen",
      "sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen",
      "locale-gen",
      "update-locale LANG=ru_RU.UTF-8",
      # Timezone
      "ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime",
      "echo 'Europe/Moscow' > /etc/timezone",
      "dpkg-reconfigure -f noninteractive tzdata",
      # Убираем старый конфиг сети
      "rm -f /etc/network/interfaces",
      # Включаем systemd-networkd и systemd-resolved
      "systemctl enable systemd-networkd",
      "systemctl enable systemd-resolved",
      "ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf",
      # cloud-init — проверяем какие юниты реально есть и включаем их
      "systemctl enable cloud-init-main.service || true",
      "systemctl enable cloud-init-local.service || true",
      "systemctl enable cloud-config.service || true",
      "systemctl enable cloud-final.service || true",
      # Чистим для шаблона
      "cloud-init clean",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",
      "sync"
    ]
  }
}