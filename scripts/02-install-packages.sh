#!/bin/bash
set -e
EDITION=$1
echo "[02] Installing packages for $EDITION"
sudo chroot chroot apt-get update
sudo chroot chroot apt-get install -y locales language-pack-ar language-pack-fr
echo "ar_DZ.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\nfr_FR.UTF-8 UTF-8" | sudo tee -a chroot/etc/locale.gen
sudo chroot chroot locale-gen
echo "LANG=en_US.UTF-8" | sudo tee chroot/etc/default/locale

if [ "$EDITION" = "pro" ]; then
  PKGS="linux-image-generic-hwe-22.04 ubuntu-minimal enlightenment terminology lightdm network-manager earlyoom dbus-x11"
elif [ "$EDITION" = "lite" ]; then
  PKGS="linux-image-generic-hwe-22.04 ubuntu-minimal enlightenment terminology lightdm dbus-x11"
else
  PKGS="linux-image-686-pae enlightenment terminology lightdm network-manager dbus-x11"
fi
sudo chroot chroot apt-get install -y --no-install-recommends $PKGS
sudo chroot chroot apt-get remove -y --purge snapd flatpak cups printer-driver-* || true
