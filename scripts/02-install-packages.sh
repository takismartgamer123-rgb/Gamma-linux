#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:-}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROOT="$ROOT/chroot"

source "$ROOT/scripts/lib/profile.sh"
load_gamma_profile "$EDITION" "$ROOT"

if [[ ! -f "$CHROOT/etc/os-release" ]]; then
    echo "ERROR: chroot/etc/os-release not found. Run 01-prepare.sh first."
    exit 1
fi

. "$CHROOT/etc/os-release"
if [[ "${ID:-}" != "debian" || "${VERSION_CODENAME:-}" != "$BASE_SUITE" ]]; then
    echo "ERROR: Expected Debian $BASE_SUITE, found ${PRETTY_NAME:-unknown}."
    exit 1
fi

CHROOT_ARCH="$(sudo chroot "$CHROOT" dpkg --print-architecture)"
if [[ "$CHROOT_ARCH" != "$BASE_ARCH" ]]; then
    echo "ERROR: Expected architecture $BASE_ARCH, found $CHROOT_ARCH."
    exit 1
fi

run_chroot() {
    sudo chroot "$CHROOT" env DEBIAN_FRONTEND=noninteractive "$@"
}

echo "[02] Updating Debian $BASE_SUITE package indexes..."
run_chroot apt-get update

echo "[02] Installing locales..."
run_chroot apt-get install -y --no-install-recommends locales
sudo tee "$CHROOT/etc/locale.gen" >/dev/null <<'EOF'
ar_DZ.UTF-8 UTF-8
en_US.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
EOF
run_chroot locale-gen
echo "LANG=en_US.UTF-8" | sudo tee "$CHROOT/etc/default/locale" >/dev/null

# Debian Live runtime: live-boot handles the early initramfs stage and
# live-config configures the live userspace after the root filesystem mounts.
# live-config-systemd is the required backend for this systemd-based image.
COMMON_PACKAGES=(
    "$KERNEL_PACKAGE"
    initramfs-tools
    live-boot
    live-boot-initramfs-tools
    live-config
    live-config-systemd
    user-setup
    sudo
    acpi
    nano
    xserver-xorg
    xinit
    x11-xserver-utils
    xauth
    zram-tools
    lightdm
    lightdm-gtk-greeter
    enlightenment
    terminology
    dbus-x11
    network-manager
)

read -r -a EXTRA_PACKAGE_ARRAY <<< "$EXTRA_PACKAGES"
PACKAGES=("${COMMON_PACKAGES[@]}" "${EXTRA_PACKAGE_ARRAY[@]}")
if [[ "$EDITION" != "legacy" ]]; then
    PACKAGES+=(calamares)
fi

echo "[02] Installing Debian packages:"
printf '  - %s\n' "${PACKAGES[@]}"
run_chroot apt-get install -y --no-install-recommends "${PACKAGES[@]}"

echo "[02] Verifying required packages..."
REQUIRED_PACKAGES=(
    "$KERNEL_PACKAGE"
    initramfs-tools
    live-boot
    live-boot-initramfs-tools
    live-config
    live-config-systemd
    user-setup
    sudo
    lightdm
    lightdm-gtk-greeter
    xserver-xorg
    enlightenment
    terminology
    zram-tools
    network-manager
)

for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! run_chroot dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
        echo "ERROR: Required package missing or not installed: $package"
        exit 1
    fi
done

if ! run_chroot test -x /usr/bin/Xorg; then
    echo "ERROR: Xorg executable missing."
    exit 1
fi

if [[ ! -f "$CHROOT/usr/share/xsessions/enlightenment.desktop" ]]; then
    echo "ERROR: Enlightenment X session file missing."
    exit 1
fi

if [[ ! -f "$CHROOT/usr/share/xgreeters/lightdm-gtk-greeter.desktop" ]]; then
    echo "ERROR: LightDM GTK greeter file missing."
    exit 1
fi

if [[ "$EDITION" != "legacy" && ! -x "$CHROOT/usr/bin/calamares" ]]; then
    echo "ERROR: Calamares executable missing for $EDITION."
    exit 1
fi

if [[ ! -f "$CHROOT/usr/share/initramfs-tools/scripts/live" ]]; then
    echo "ERROR: Debian live-boot initramfs script is missing."
    exit 1
fi

echo "[02] Enabling LightDM..."
run_chroot systemctl enable lightdm.service >/dev/null 2>&1 || true

echo "[02] Rebuilding initramfs with Debian live-boot hooks..."
run_chroot update-initramfs -c -k all || run_chroot update-initramfs -u -k all

if ! find "$CHROOT/boot" -maxdepth 1 -type f -name 'initrd.img-*' -print -quit | grep -q .; then
    echo "ERROR: No initramfs generated."
    exit 1
fi

echo "[02] Removing unwanted optional packages and build cache..."
run_chroot apt-get purge -y snapd flatpak cups || true
run_chroot apt-get autoremove -y
run_chroot apt-get clean

if run_chroot dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | grep -qx 'casper'; then
    echo "ERROR: An Ubuntu Casper package was installed unexpectedly."
    exit 1
fi

echo
echo "=========================================="
echo " Gamma Linux Debian Package Stage"
echo " Edition : $EDITION"
echo " Base    : Debian $BASE_SUITE"
echo " Arch    : $BASE_ARCH"
echo " Kernel  : $KERNEL_PACKAGE"
echo " Live    : live-boot + live-config"
echo " Xorg    : OK"
echo " LightDM : OK"
if [[ "$EDITION" != "legacy" ]]; then echo " Calamares: OK"; else echo " Calamares: not included"; fi
echo " Initramfs: OK"
echo "=========================================="
