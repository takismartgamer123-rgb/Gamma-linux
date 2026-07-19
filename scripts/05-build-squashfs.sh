#!/usr/bin/env bash
set -euo pipefail

echo "[05] Building SquashFS"

# ==========================================
# Prepare
# ==========================================
sudo mkdir -p iso/casper

if [ -f iso/casper/filesystem.squashfs ]; then
    echo "[05] Removing old SquashFS..."
    sudo rm -f iso/casper/filesystem.squashfs
fi

# ==========================================
# Cleanup chroot
# ==========================================
echo "[05] Cleaning temporary files..."

sudo rm -rf \
    chroot/tmp/* \
    chroot/var/tmp/* \
    chroot/var/cache/apt/archives/* \
    2>/dev/null || true


# ==========================================
# Build SquashFS
# ==========================================
echo "[05] Compressing filesystem..."

sudo mksquashfs \
    chroot \
    iso/casper/filesystem.squashfs \
    -comp zstd \
    -Xcompression-level 19 \
    -b 1M \
    -noappend \
    -e chroot/dev \
    -e chroot/proc \
    -e chroot/sys


# ==========================================
# Kernel + Initramfs
# ==========================================
echo "[05] Copying kernel..."

VMLINUX=$(find chroot/boot -maxdepth 1 -name "vmlinuz-*" | sort | head -n1)
INITRD=$(find chroot/boot -maxdepth 1 -name "initrd.img-*" | sort | head -n1)

if [ -z "$VMLINUX" ]; then
    echo "ERROR: Kernel missing"
    exit 1
fi

if [ -z "$INITRD" ]; then
    echo "ERROR: Initramfs missing"
    exit 1
fi

sudo cp "$VMLINUX" iso/casper/vmlinuz
sudo cp "$INITRD" iso/casper/initrd.lz


# ==========================================
# Report
# ==========================================
SIZE=$(du -h iso/casper/filesystem.squashfs | awk '{print $1}')

echo
echo "================================="
echo " SquashFS completed successfully"
echo " Size: $SIZE"
echo " Kernel: $(basename "$VMLINUX")"
echo " Initrd: $(basename "$INITRD")"
echo "================================="
