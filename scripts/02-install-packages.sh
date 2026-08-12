#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROOT="$ROOT/chroot"

export DEBIAN_FRONTEND=noninteractive

echo "[02] Installing packages for $EDITION"

# ==========================================================
# Validate edition
# ==========================================================

case "$EDITION" in
    pro|lite|legacy)
        ;;
    *)
        echo "ERROR: Unknown edition: $EDITION"
        exit 1
        ;;
esac

# ==========================================================
# Repository setup
# ==========================================================

if grep -qi '^ID=ubuntu' "$CHROOT/etc/os-release"; then

    echo "[02] Ubuntu detected"

    sudo chroot "$CHROOT" apt-get update

    sudo chroot "$CHROOT" apt-get install -y \
        software-properties-common

    sudo chroot "$CHROOT" add-apt-repository universe

    sudo chroot "$CHROOT" apt-get update

elif grep -qi '^ID=debian' "$CHROOT/etc/os-release"; then

    echo "[02] Debian detected"

    sudo chroot "$CHROOT" apt-get update

else

    echo "ERROR: Unsupported base distribution."
    cat "$CHROOT/etc/os-release"
    exit 1

fi

# ==========================================================
# Locale
# ==========================================================

if [ "$EDITION" = "legacy" ]; then

    sudo chroot "$CHROOT" apt-get install -y \
        locales \
        keyboard-configuration

else

    sudo chroot "$CHROOT" apt-get install -y \
        locales \
        language-pack-ar \
        language-pack-fr \
        keyboard-configuration

fi

sudo tee "$CHROOT/etc/locale.gen" >/dev/null <<EOF
ar_DZ.UTF-8 UTF-8
en_US.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
EOF

sudo chroot "$CHROOT" locale-gen

sudo tee "$CHROOT/etc/default/locale" >/dev/null <<EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
EOF

# ==========================================================
# Common desktop / Live / Installer packages
# ==========================================================

COMMON_PKGS=(
    initramfs-tools

    xserver-xorg
    xserver-xorg-core
    xserver-xorg-video-all
    x11-xserver-utils
    xinit
    xauth
    mesa-utils

    lightdm
    lightdm-gtk-greeter

    policykit-1
    pkexec

    xdg-utils
    gvfs
    gvfs-backends

    enlightenment
    terminology

    network-manager
    dbus-x11
    udisks2

    parted
    dosfstools
    e2fsprogs
    btrfs-progs
    gdisk

    rsync
    cryptsetup

    calamares
    calamares-settings-debian

    zram-tools
)

# ==========================================================
# Edition-specific packages
# ==========================================================

case "$EDITION" in

    pro)

        PKGS=(
            "${COMMON_PKGS[@]}"

            linux-image-generic-hwe-22.04

            casper
            ubuntu-minimal

            xserver-xorg-video-all

            earlyoom
        )

        ;;

    lite)

        PKGS=(
            "${COMMON_PKGS[@]}"

            linux-image-generic-hwe-22.04

            casper
            ubuntu-minimal

            xserver-xorg-video-all
        )

        ;;

    legacy)

        PKGS=(
            "${COMMON_PKGS[@]}"

            linux-image-686-pae

            grub-pc
            grub-pc-bin
            grub-efi-ia32-bin
        )

        ;;

esac

# ==========================================================
# Install
# ==========================================================

echo
echo "[02] Installing:"
printf '  %s\n' "${PKGS[@]}"
echo

sudo chroot "$CHROOT" apt-get install \
    -y \
    --no-install-recommends \
    "${PKGS[@]}"

# ==========================================================
# Verify critical components
# ==========================================================

echo "[02] Verifying critical packages..."

sudo chroot "$CHROOT" test -x /usr/bin/Xorg
sudo chroot "$CHROOT" test -x /usr/sbin/lightdm
sudo chroot "$CHROOT" test -x /usr/bin/calamares
sudo chroot "$CHROOT" test -x /usr/sbin/zramswap
sudo chroot "$CHROOT" test -f /usr/share/xsessions/enlightenment.desktop

echo "[02] Critical packages verified."

# ==========================================================
# Initramfs
# ==========================================================

echo "[02] Rebuilding initramfs..."

sudo chroot "$CHROOT" update-initramfs -c -k all || true
sudo chroot "$CHROOT" update-initramfs -u -k all

# ==========================================================
# Remove Snap / Flatpak
# ==========================================================

REMOVE_PKGS=(
    snapd
    flatpak
)

sudo chroot "$CHROOT" apt-get purge -y \
    "${REMOVE_PKGS[@]}" || true

# ==========================================================
# Package cleanup
# ==========================================================

sudo chroot "$CHROOT" apt-get clean

echo "[02] Package installation completed."
