#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

echo "[02] Installing packages for $EDITION"

export DEBIAN_FRONTEND=noninteractive

sudo chroot chroot apt-get update

# ==========================
# Locales
# ==========================
if [ "$EDITION" = "legacy" ]; then
    sudo chroot chroot apt-get install -y locales
else
    sudo chroot chroot apt-get install -y \
        locales \
        language-pack-ar \
        language-pack-fr
fi

cat <<EOF | sudo tee chroot/etc/locale.gen >/dev/null
ar_DZ.UTF-8 UTF-8
en_US.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
EOF

sudo chroot chroot locale-gen

echo "LANG=en_US.UTF-8" | sudo tee chroot/etc/default/locale >/dev/null

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
"
;;

*)
echo "Unknown edition: $EDITION"
exit 1
;;

esac

sudo chroot chroot apt-get install \
    -y \
    --no-install-recommends \
    $PKGS

# ==========================
# Cleanup
# ==========================

REMOVE_PKGS="snapd flatpak cups"

sudo chroot chroot apt-get purge -y $REMOVE_PKGS || true
sudo chroot chroot apt-get autoremove -y
sudo chroot chroot apt-get clean

echo "[02] Packages installed successfully."
