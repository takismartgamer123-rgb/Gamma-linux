#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

echo "[02] Installing packages for $EDITION"

export DEBIAN_FRONTEND=noninteractive

# ==========================================
# Detect Base
# ==========================================

if [ ! -f chroot/etc/os-release ]; then
    echo "ERROR: chroot/etc/os-release not found"
    exit 1
fi

. chroot/etc/os-release

echo "[02] Base: ${PRETTY_NAME:-unknown}"

# ==========================================
# Repository Setup
# ==========================================

if [ "${ID:-}" = "ubuntu" ]; then

    echo "[02] Ubuntu detected"

    sudo chroot chroot apt-get update

    sudo chroot chroot apt-get install -y \
        software-properties-common

    sudo chroot chroot add-apt-repository universe || true

    sudo chroot chroot apt-get update

elif [ "${ID:-}" = "debian" ]; then

    echo "[02] Debian detected"

    sudo chroot chroot apt-get update

else

    echo "ERROR: Unsupported base: ${ID:-unknown}"
    exit 1

fi

# ==========================================
# Locales
# ==========================================

echo "[02] Installing locales..."

if [ "$EDITION" = "legacy" ]; then

    sudo chroot chroot apt-get install -y \
        locales

else

    sudo chroot chroot apt-get install -y \
        locales \
        language-pack-ar \
        language-pack-fr

fi

sudo tee chroot/etc/locale.gen >/dev/null <<EOF
ar_DZ.UTF-8 UTF-8
en_US.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
EOF

sudo chroot chroot locale-gen

echo "LANG=en_US.UTF-8" | \
    sudo tee chroot/etc/default/locale >/dev/null

# ==========================================
# Common Desktop Packages
# ==========================================

COMMON_PKGS="
initramfs-tools

xserver-xorg
xinit
x11-xserver-utils
xauth

lightdm
lightdm-gtk-greeter

enlightenment
terminology

dbus-x11
"

# ==========================================
# Edition Packages
# ==========================================

case "$EDITION" in

    pro)

        PKGS="
        linux-image-generic-hwe-22.04
        casper
        ubuntu-minimal

        $COMMON_PKGS

        network-manager
        earlyoom

        calamares
        "

        ;;

    lite)

        PKGS="
        linux-image-generic-hwe-22.04
        casper
        ubuntu-minimal

        $COMMON_PKGS

        network-manager

        calamares
        "

        ;;

    legacy)

        PKGS="
        linux-image-686-pae

        $COMMON_PKGS

        network-manager
        "

        ;;

    *)

        echo "ERROR: Unknown edition: $EDITION"
        exit 1

        ;;

esac

# ==========================================
# Install Packages
# ==========================================

echo
echo "[02] Installing packages:"
echo "$PKGS"
echo

sudo chroot chroot apt-get install \
    -y \
    --no-install-recommends \
    $PKGS

# ==========================================
# Verify Desktop
# ==========================================

echo "[02] Verifying desktop environment..."

REQUIRED_PKGS="
lightdm
lightdm-gtk-greeter
xserver-xorg
enlightenment
terminology
"

for PKG in $REQUIRED_PKGS; do

    if ! sudo chroot chroot dpkg -s "$PKG" >/dev/null 2>&1; then

        echo "ERROR: Required package missing: $PKG"
        exit 1

    fi

done

# ==========================================
# Verify Xorg
# ==========================================

if [ ! -x chroot/usr/bin/Xorg ]; then

    echo "ERROR: Xorg executable missing"
    exit 1

fi

echo "[02] Xorg OK"

# ==========================================
# Verify Enlightenment Session
# ==========================================

if [ ! -f chroot/usr/share/xsessions/enlightenment.desktop ]; then

    echo "ERROR: Enlightenment session missing:"
    echo "       chroot/usr/share/xsessions/enlightenment.desktop"

    exit 1

fi

echo "[02] Enlightenment session OK"

# ==========================================
# Verify LightDM Greeter
# ==========================================

if [ ! -f chroot/usr/share/xgreeters/lightdm-gtk-greeter.desktop ]; then

    echo "ERROR: LightDM GTK greeter missing"
    exit 1

fi

echo "[02] LightDM greeter OK"

# ==========================================
# Verify Calamares
# ==========================================

if [ "$EDITION" != "legacy" ]; then

    if [ ! -x chroot/usr/bin/calamares ]; then

        echo "ERROR: Calamares missing for $EDITION"
        exit 1

    fi

    echo "[02] Calamares OK"

fi

# ==========================================
# Enable LightDM
# ==========================================

echo "[02] Enabling LightDM..."

sudo chroot chroot systemctl enable lightdm.service \
    >/dev/null 2>&1 || true

# ==========================================
# Rebuild Initramfs
# ==========================================

echo "[02] Rebuilding initramfs..."

sudo chroot chroot update-initramfs -c -k all || \
sudo chroot chroot update-initramfs -u -k all

# ==========================================
# Verify Initramfs
# ==========================================

if ! find chroot/boot \
    -maxdepth 1 \
    -type f \
    -name 'initrd.img-*' \
    | grep -q .; then

    echo "ERROR: No initramfs generated"
    exit 1

fi

echo "[02] Initramfs OK"

# ==========================================
# Cleanup
# ==========================================

echo "[02] Cleaning unwanted packages..."

sudo chroot chroot apt-get purge -y \
    snapd \
    flatpak \
    cups \
    || true

sudo chroot chroot apt-get autoremove -y

sudo chroot chroot apt-get clean

# ==========================================
# Final Report
# ==========================================

echo
echo "=========================================="
echo " Gamma Linux Package Stage Completed"
echo " Edition : $EDITION"
echo " Base    : ${PRETTY_NAME:-unknown}"
echo " Xorg    : OK"
echo " LightDM : OK"
echo " Greeter : OK"
echo " E17/E25 : OK"
if [ "$EDITION" != "legacy" ]; then
echo " Calamares: OK"
fi
echo " Initramfs: OK"
echo "=========================================="
echo
