#!/bin/bash
set -e
EDITION=$1
echo "[01] Preparing chroot for $EDITION"
rm -rf chroot iso output
mkdir -p chroot iso output assets

if [ "$EDITION" = "legacy" ]; then
  sudo debootstrap --arch=i386 --include=systemd-sysv bookworm chroot http://deb.debian.org/debian/
else
  sudo debootstrap --arch=amd64 --include=systemd-sysv jammy chroot http://archive.ubuntu.com/ubuntu/
fi
sudo mount --bind /dev chroot/dev
sudo mount --bind /proc chroot/proc
sudo mount --bind /sys chroot/sys
echo "nameserver 8.8.8.8" | sudo tee chroot/etc/resolv.conf > /dev/null
