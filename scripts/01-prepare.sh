#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

echo "[01] Preparing build environment ($EDITION)"

# تنظيف
sudo umount chroot/dev 2>/dev/null || true
sudo umount chroot/proc 2>/dev/null || true
sudo umount chroot/sys 2>/dev/null || true

sudo rm -rf chroot iso output

mkdir -p chroot
mkdir -p iso
mkdir -p output

# اختيار التوزيعة
if [ "$EDITION" = "legacy" ]; then
    ARCH="i386"
    RELEASE="bookworm"
    MIRROR="http://deb.debian.org/debian"
else
    ARCH="amd64"
    RELEASE="jammy"
    MIRROR="http://archive.ubuntu.com/ubuntu"
fi

echo "[01] Creating base system..."

sudo debootstrap \
    --arch="$ARCH" \
    --include=systemd-sysv \
    "$RELEASE" \
    chroot \
    "$MIRROR"

echo "[01] Mounting virtual filesystems..."

sudo mount --bind /dev chroot/dev
sudo mount --bind /proc chroot/proc
sudo mount --bind /sys chroot/sys

echo "nameserver 8.8.8.8" | sudo tee chroot/etc/resolv.conf >/dev/null

echo "[01] Done."
