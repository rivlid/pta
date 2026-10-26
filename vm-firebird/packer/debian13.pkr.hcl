packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Шаблон под сервер БД Firebird 5.
# Сам Firebird НЕ ставится — только ОС, зависимости и разметка дисков.
# Диски у клона (добавляет Terraform):
#   scsi0 -> sda  система (растёт через cloud-init growpart)
#   scsi1 -> sdb  swap        (размечается при первой загрузке, fb-disks.service)
#   scsi2 -> sdc  /mnt/db     (размечается при первой загрузке, fb-disks.service)

source "proxmox-iso" "debian13" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node    = var.proxmox_node
  vm_id   = 9002
  vm_name = "debian-13-firebird"
  boot_iso {
    iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.7.0-amd64-netinst.iso"
    iso_checksum     = "sha256:a7ef94ac2fb9a7fec454552abd629b7cc9d5155c886165a45649f5ce6167e355"
    iso_storage_pool = "local"
    unmount          = true
  }
  cores   = 2
  memory  = 2048
  sockets = 1

  scsi_controller = "virtio-scsi-single"

  disks {
    disk_size    = "20G"
    storage_pool = var.storage_pool
    type         = "scsi"
    discard      = true
    io_thread    = true
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

  ssh_username           = "root"
  ssh_password           = "debian"
  ssh_timeout            = "30m"
  ssh_handshake_attempts = 50

  template_name        = "debian-13-firebird"
  template_description = "Debian 13 - Firebird 5 DB server template (swap on scsi1, /mnt/db on scsi2, FB not installed)"
  unmount_iso          = true
}

build {
  sources = ["source.proxmox-iso.debian13"]

  # Файлы для подготовки дисков и тюнинга
  provisioner "file" {
    source      = "packer/files/"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      # ВСЁ ставим одной командой: пакет systemd-resolved сразу переключает
      # /etc/resolv.conf на свой stub, а сервис ещё не запущен -> DNS пропадает
      # и любой следующий apt-get install падает с ошибкой разрешения имён.
      # Зависимости Firebird 5 (официальный tarball): libtommath1 libicu76 libncurses6 libatomic1
      "apt-get install -y cloud-init qemu-guest-agent curl wget locales systemd-resolved netplan.io cloud-guest-utils parted libtommath1 libicu76 libncurses6 libatomic1 htop iotop sysstat",
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
      # cloud-init
      "systemctl enable cloud-init-main.service || true",
      "systemctl enable cloud-init-local.service || true",
      "systemctl enable cloud-config.service || true",
      "systemctl enable cloud-final.service || true",
      # Swap — отдельным диском scsi1 (без swap-файла), resume не нужен
      "echo RESUME=none > /etc/initramfs-tools/conf.d/resume",
      "update-initramfs -u",
      # Разметка swap и /mnt/db при первой загрузке клона
      "install -m 0755 /tmp/fb-disks.sh /usr/local/sbin/fb-disks.sh",
      "install -m 0644 /tmp/fb-disks.service /etc/systemd/system/fb-disks.service",
      "systemctl enable fb-disks.service",
      "mkdir -p /mnt/db",
      # Тюнинг ядра и лимиты для будущего firebird.service
      "install -m 0644 /tmp/99-firebird.conf /etc/sysctl.d/99-firebird.conf",
      "install -d /etc/systemd/system/firebird.service.d",
      "install -m 0644 /tmp/firebird-limits.conf /etc/systemd/system/firebird.service.d/limits.conf",
      "rm -f /tmp/fb-disks.sh /tmp/fb-disks.service /tmp/99-firebird.conf /tmp/firebird-limits.conf",
      # Чистим для шаблона
      "apt-get clean",
      "cloud-init clean --logs",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",
      "sync"
    ]
  }
}
