#!/bin/bash
# Подготовка дополнительных дисков под Firebird при загрузке клона.
# Запускается systemd-юнитом fb-disks.service на каждой загрузке,
# но трогает диск ТОЛЬКО если он полностью пустой (нет таблицы разделов и ФС).
#
#   scsi1 -> swap         (раздел на весь диск)
#   scsi2 -> /mnt/db ext4 (раздел на весь диск, под базы)
#
# Диски ищем по by-id (имя драйва Proxmox), а не по sdb/sdc — так надёжнее.

set -euo pipefail

SWAP_DISK=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1
DATA_DISK=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2
DATA_MOUNT=/mnt/db
DATA_LABEL=fbdata

log() { echo "fb-disks: $*"; }

# true, если на диске нет ни таблицы разделов, ни ФС
is_blank() { ! blkid -p "$1" >/dev/null 2>&1; }

# Создать один GPT-раздел на весь диск и вернуть путь к нему
make_single_part() {
  local disk=$1 type=$2
  parted -s "$disk" mklabel gpt mkpart primary "$type" 1MiB 100%
  partprobe "$disk" || true
  udevadm settle
  echo "${disk}-part1"
}

udevadm settle

# ---------- swap ----------
if [ -b "$SWAP_DISK" ]; then
  if is_blank "$SWAP_DISK"; then
    log "размечаю swap на $SWAP_DISK"
    part=$(make_single_part "$SWAP_DISK" linux-swap)
    mkswap -L swap "$part"
    uuid=$(blkid -s UUID -o value "$part")
    grep -q "UUID=$uuid" /etc/fstab || echo "UUID=$uuid none swap sw,nofail 0 0" >> /etc/fstab
  fi
  swapon -a || true
else
  log "диск под swap (scsi1) не найден — пропускаю"
fi

# ---------- данные ----------
if [ -b "$DATA_DISK" ]; then
  if is_blank "$DATA_DISK"; then
    log "размечаю $DATA_DISK под $DATA_MOUNT"
    part=$(make_single_part "$DATA_DISK" ext4)
    # -m 1: резерв под root 1% вместо 5% (на 750G это ~30G экономии)
    mkfs.ext4 -q -L "$DATA_LABEL" -m 1 "$part"
    uuid=$(blkid -s UUID -o value "$part")
    mkdir -p "$DATA_MOUNT"
    grep -q "UUID=$uuid" /etc/fstab || \
      echo "UUID=$uuid $DATA_MOUNT ext4 defaults,noatime,nofail 0 2" >> /etc/fstab
    systemctl daemon-reload
  fi
  mkdir -p "$DATA_MOUNT"
  mountpoint -q "$DATA_MOUNT" || mount "$DATA_MOUNT" || log "не удалось смонтировать $DATA_MOUNT"
else
  log "диск под базы (scsi2) не найден — пропускаю"
fi
