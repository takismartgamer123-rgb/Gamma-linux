#!/usr/bin/env bash
set -euo pipefail

echo "[05] Building SquashFS"

sudo mkdir -p iso/casper

sudo mksquashfs \
    chroot \
    iso/casper/filesystem.squashfs \
    -comp zstd \
    -Xcompression-level 19 \
    -b 1M \
    -e dev proc sys

VMLINUX=$(find chroot/boot -name "vmlinuz-*" | head -n1)
INITRD=$(find chroot/boot -name "initrd.img-*" | head -n1)

if [ -z "$VMLINUX" ] || [ -z "$INITRD" ]; then
    echo "Kernel أو initramfs غير موجود!"
    exit 1
fi

sudo cp "$VMLINUX" iso/casper/vmlinuz
sudo cp "$INITRD" iso/casper/initrd.lz

echo "[05] SquashFS completed."
