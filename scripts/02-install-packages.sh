#!/usr/bin/env bash
set -euo pipefail

EDITION="$1"

echo "[02] Installing packages for $EDITION"

sudo chroot chroot apt-get update

# ==========================
# Locales
# ==========================
if [ "$EDITION" = "legacy" ]; then
    sudo chroot chroot apt-get install -y locales
else
    sudo chroot chroot apt-get install -y locales language-pack-ar language-pack-fr
fi

echo "ar_DZ.UTF-8 UTF-8
en_US.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8" | sudo tee -a chroot/etc/locale.gen > /dev/null

sudo chroot chroot locale-gen

echo "LANG=en_US.UTF-8" | sudo tee chroot/etc/default/locale > /dev/null

# ==========================
# Packages
# ==========================
case "$EDITION" in

pro)
PKGS="
linux-image-generic-hwe-22.04
initramfs-tools
ubuntu-minimal
enlightenment
terminology
lightdm
network-manager
earlyoom
dbus-x11
edje-utils
wireless-tools
"
;;

lite)
PKGS="
linux-image-generic-hwe-22.04
initramfs-tools
ubuntu-minimal
enlightenment
terminology
lightdm
dbus-x11
edje-utils
"
;;

legacy)
PKGS="
linux-image-686-pae
enlightenment
terminology
lightdm
network-manager
dbus-x11
firmware-linux
firmware-linux-nonfree
wireless-tools
"
;;

*)
echo "Unknown edition: $EDITION"
exit 1
;;

esac

sudo chroot chroot apt-get install -y --no-install-recommends $PKGS

# ==========================
# Cleanup
# ==========================
sudo chroot chroot apt-get remove -y --purge \
snapd \
flatpak \
cups \
printer-driver-* \
bluetooth \
|| true

sudo chroot chroot apt-get autoremove -y
sudo chroot chroot apt-get clean

echo "[02] Packages installed successfully."
