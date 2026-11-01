#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:-}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROOT="$ROOT/chroot"
ISO_DIR="$ROOT/iso"
OUTPUT_DIR="$ROOT/output"

source "$ROOT/scripts/lib/profile.sh"
load_gamma_profile "$EDITION" "$ROOT"

echo "[01] Preparing Debian chroot for Gamma $EDITION"
echo "[01] Suite      : $BASE_SUITE"
echo "[01] Architecture: $BASE_ARCH"
echo "[01] Mirror     : $BASE_MIRROR"

# This stage intentionally starts a clean build. It removes generated
# chroot/, iso/ and output/ directories, so keep backups outside the repo.
echo "[01] Unmounting any previous chroot mounts..."
sudo umount -R "$CHROOT/dev" 2>/dev/null || true
sudo umount "$CHROOT/proc" 2>/dev/null || true
sudo umount "$CHROOT/sys" 2>/dev/null || true
sudo umount -R "$CHROOT/run" 2>/dev/null || true

echo "[01] Removing previous generated build directories..."
sudo rm -rf "$CHROOT" "$ISO_DIR" "$OUTPUT_DIR"
mkdir -p "$CHROOT" "$ISO_DIR" "$OUTPUT_DIR"

echo "[01] Bootstrapping Debian $BASE_SUITE ($BASE_ARCH)..."
sudo debootstrap --arch="$BASE_ARCH" --include=systemd-sysv,ca-certificates,apt-utils "$BASE_SUITE" "$CHROOT" "$BASE_MIRROR"

echo "[01] Writing Debian archive sources..."
sudo mkdir -p "$CHROOT/etc/apt/sources.list.d"
# Trixie may use deb822 sources by default; remove the generated file so the
# explicit profile-controlled sources below are the sole configured entries.
sudo rm -f "$CHROOT/etc/apt/sources.list.d/debian.sources"
sudo tee "$CHROOT/etc/apt/sources.list" >/dev/null <<EOF
deb $BASE_MIRROR $BASE_SUITE $APT_COMPONENTS
deb $BASE_MIRROR $BASE_SUITE-updates $APT_COMPONENTS
deb $SECURITY_MIRROR $BASE_SUITE-security $APT_COMPONENTS
EOF

echo "[01] Configuring DNS..."
sudo rm -f "$CHROOT/etc/resolv.conf"
if [[ -f /etc/resolv.conf ]]; then
    sudo cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf"
else
    sudo tee "$CHROOT/etc/resolv.conf" >/dev/null <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
fi

echo "[01] Mounting virtual filesystems..."
sudo mount --rbind /dev "$CHROOT/dev"
sudo mount --make-rslave "$CHROOT/dev"
sudo mount -t proc proc "$CHROOT/proc"
sudo mount -t sysfs sysfs "$CHROOT/sys"

sudo mkdir -p "$CHROOT/etc" "$CHROOT/var/lib"

echo "[01] Debian $BASE_SUITE chroot prepared."
