#!/bin/bash
set -e
EDITION=$1

echo "[02] Installing packages for $EDITION"

sudo chroot chroot apt-get update

# اللغات
sudo chroot chroot apt-get install -y locales language-pack-ar-base language-pack-fr-base
echo "ar_DZ.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\nfr_FR.UTF-8 UTF-8" | sudo tee -a chroot/etc/locale.gen
sudo chroot chroot locale-gen
echo "LANG=en_US.UTF-8" | sudo tee chroot/etc/default/locale

# الحزم حسب النسخة
if [ "$EDITION" = "pro" ]; then
  PKGS="linux-image-generic-hwe-22.04 ubuntu-minimal enlightenment terminology lightdm network-manager earlyoom dbus-x11 firmware-linux firmware-linux-nonfree wireless-tools"
elif [ "$EDITION" = "lite" ]; then
  PKGS="linux-image-generic-hwe-22.04 ubuntu-minimal enlightenment terminology lightdm dbus-x11"
else
  PKGS="linux-image-686-pae enlightenment terminology lightdm network-manager dbus-x11 firmware-linux firmware-linux-nonfree wireless-tools"
fi

sudo chroot chroot apt-get install -y --no-install-recommends $PKGS

# حذف الزبل
sudo chroot chroot apt-get remove -y --purge snapd flatpak cups printer-driver-* || true
sudo chroot chroot apt-get autoremove -y
sudo chroot chroot apt-get clean
