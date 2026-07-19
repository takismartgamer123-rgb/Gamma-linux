#!/usr/bin/env bash
set -euo pipefail

EDITION="$1"

echo "[01] Preparing chroot for $EDITION"

sudo umount chroot/dev 2>/dev/null || true
sudo umount chroot/proc 2>/dev/null || true
sudo umount chroot/sys 2>/dev/null || true

rm -rf chroot iso output
mkdir -p chroot iso output assets

if [ "$EDITION" = "legacy" ]; then
    sudo debootstrap \
        --arch=i386 \
        --include=systemd-sysv \
        bookworm \
        chroot \
        http://deb.debian.org/debian/

    cat <<EOF | sudo tee chroot/etc/apt/sources.list > /dev/null
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

else
    sudo debootstrap \
        --arch=amd64 \
        --include=systemd-sysv \
        jammy \
        chroot \
        http://archive.ubuntu.com/ubuntu/

    cat <<EOF | sudo tee chroot/etc/apt/sources.list > /dev/null
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
EOF
fi

sudo mount --bind /dev chroot/dev
sudo mount --bind /proc chroot/proc
sudo mount --bind /sys chroot/sys

echo "nameserver 8.8.8.8" | sudo tee chroot/etc/resolv.conf > /dev/null

sudo chroot chroot apt-get update

echo "[01] Chroot ready."
