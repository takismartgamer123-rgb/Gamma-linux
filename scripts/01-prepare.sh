#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:-}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CHROOT="$ROOT/chroot"
ISO_DIR="$ROOT/iso"
OUTPUT_DIR="$ROOT/output"

echo "[01] Preparing Gamma Linux build environment..."

# ==========================================================
# Validate edition
# ==========================================================

case "$EDITION" in
    pro|lite)
        ARCH="amd64"
        RELEASE="jammy"
        MIRROR="https://archive.ubuntu.com/ubuntu"
        ;;
    legacy)
        ARCH="i386"
        RELEASE="bookworm"
        MIRROR="https://deb.debian.org/debian"
        ;;
    *)
        echo "Usage: $0 <pro|lite|legacy>"
        exit 1
        ;;
esac

echo "[01] Edition : $EDITION"
echo "[01] Arch    : $ARCH"
echo "[01] Release : $RELEASE"
echo "[01] Mirror  : $MIRROR"

# ==========================================================
# Cleanup previous build
# ==========================================================

echo "[01] Cleaning previous build..."

sudo umount -R "$CHROOT/dev" 2>/dev/null || true
sudo umount "$CHROOT/proc" 2>/dev/null || true
sudo umount "$CHROOT/sys" 2>/dev/null || true
sudo umount "$CHROOT/run" 2>/dev/null || true

sudo rm -rf \
    "$CHROOT" \
    "$ISO_DIR" \
    "$OUTPUT_DIR"

mkdir -p \
    "$CHROOT" \
    "$ISO_DIR" \
    "$OUTPUT_DIR"

# ==========================================================
# Bootstrap base system
# ==========================================================

echo "[01] Creating base system..."

sudo debootstrap \
    --arch="$ARCH" \
    --include=systemd-sysv,ca-certificates,apt-utils \
    "$RELEASE" \
    "$CHROOT" \
    "$MIRROR"

# ==========================================================
# DNS
# ==========================================================

echo "[01] Configuring DNS..."

sudo rm -f "$CHROOT/etc/resolv.conf"

if [ -f /etc/resolv.conf ]; then
    sudo cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf"
else
    sudo tee "$CHROOT/etc/resolv.conf" >/dev/null <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
fi

# ==========================================================
# Virtual filesystems
#
# Keep these mounted for scripts 02, 03 and 04.
# Script 04 performs the final unmount.
# ==========================================================

echo "[01] Mounting virtual filesystems..."

sudo mount --rbind /dev "$CHROOT/dev"
sudo mount --make-rslave "$CHROOT/dev"

sudo mount -t proc proc "$CHROOT/proc"
sudo mount -t sysfs sysfs "$CHROOT/sys"

# ==========================================================
# Basic chroot identity
# ==========================================================

sudo mkdir -p \
    "$CHROOT/etc" \
    "$CHROOT/var/lib"

echo "[01] Base system prepared successfully."
