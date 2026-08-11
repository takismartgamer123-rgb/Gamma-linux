#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROOT="$ROOT/chroot"

echo "[04] Configuring Gamma Linux ($EDITION)"

# ==========================================================
# Cleanup mounts on exit
# ==========================================================

cleanup() {
    sync || true

    sudo umount -R "$CHROOT/dev" 2>/dev/null || true
    sudo umount "$CHROOT/proc" 2>/dev/null || true
    sudo umount "$CHROOT/sys" 2>/dev/null || true
}

trap cleanup EXIT

# ==========================================================
# Validate edition
# ==========================================================

case "$EDITION" in

    pro)
        SW=80
        VFS=50
        DIRTY=20
        HOSTNAME="gamma-pro"
        ;;

    lite)
        SW=100
        VFS=100
        DIRTY=10
        HOSTNAME="gamma-lite"
        ;;

    legacy)
        SW=100
        VFS=150
        DIRTY=5
        HOSTNAME="gamma-legacy"
        ;;

    *)
        echo "ERROR: Unknown edition '$EDITION'"
        exit 1
        ;;

esac

# ==========================================================
# Basic directories
# ==========================================================

echo "[04] Creating system directories..."

sudo mkdir -p \
    "$CHROOT/etc/lightdm" \
    "$CHROOT/etc/xdg/autostart" \
    "$CHROOT/etc/sysctl.d" \
    "$CHROOT/etc/systemd/system" \
    "$CHROOT/usr/local/bin" \
    "$CHROOT/usr/share/applications" \
    "$CHROOT/etc/calamares" \
    "$CHROOT/etc/calamares/branding/gamma" \
    "$CHROOT/etc/calamares/modules"

# ==========================================================
# System identity
# ==========================================================

echo "[04] Configuring Gamma identity..."

sudo tee "$CHROOT/etc/hostname" >/dev/null <<EOF
$HOSTNAME
EOF

sudo tee "$CHROOT/etc/motd" >/dev/null <<EOF

========================================
        Gamma Linux
        No PC deserves to die.
========================================

EOF

# ==========================================================
# /etc/os-release
# ==========================================================

if [ "$EDITION" = "legacy" ]; then
    BASE_PRETTY="Gamma Linux Legacy"
else
    if [ "$EDITION" = "pro" ]; then
        BASE_PRETTY="Gamma Linux Pro"
    else
        BASE_PRETTY="Gamma Linux Lite"
    fi
fi

sudo tee "$CHROOT/etc/gamma-release" >/dev/null <<EOF
GAMMA_NAME="Gamma Linux"
GAMMA_EDITION="$EDITION"
GAMMA_VERSION="2.7"
EOF

# Keep the base distribution identity available to packages,
# while adding Gamma-specific information.

sudo tee "$CHROOT/etc/os-release.gamma" >/dev/null <<EOF
NAME="Gamma Linux"
PRETTY_NAME="$BASE_PRETTY"
VERSION="2.7"
ID=gamma
ID_LIKE=debian
VERSION_ID="2.7"
HOME_URL="https://github.com/takismartgamer123-rgb/Gamma-linux"
EOF

# ==========================================================
# LightDM
# ==========================================================

echo "[04] Configuring LightDM..."

sudo tee "$CHROOT/etc/lightdm/lightdm.conf" >/dev/null <<EOF
[Seat:*]
user-session=enlightenment
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
greeter-show-manual-login=true
allow-guest=false
EOF

# ==========================================================
# Gamma Control Center autostart
# ==========================================================

echo "[04] Configuring Gamma Control Center..."

sudo tee "$CHROOT/etc/xdg/autostart/gamma-cc.desktop" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Gamma Control Center
Comment=Gamma Linux system control center
Exec=gamma-cc
OnlyShowIn=Enlightenment;
X-GNOME-Autostart-enabled=true
NoDisplay=false
EOF

# ==========================================================
# First Boot
# ==========================================================

echo "[04] Installing Gamma first-boot helper..."

sudo tee "$CHROOT/usr/local/bin/gamma-firstboot" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

FLAG="$HOME/.config/gamma/.firstboot_done"

if [ -f "$FLAG" ]; then
    exit 0
fi

mkdir -p "$HOME/.config/gamma"

echo "Gamma Linux first boot"

# ----------------------------------------------------------
# Future customization hooks
# ----------------------------------------------------------
#
# Theme
# Wallpaper
# Enlightenment profile
# Gamma CC defaults
# User configuration
#
# These remain intentionally minimal for v2.7.
# ----------------------------------------------------------

touch "$FLAG"

exit 0
EOF

sudo chmod +x "$CHROOT/usr/local/bin/gamma-firstboot"

sudo tee "$CHROOT/etc/xdg/autostart/gamma-firstboot.desktop" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Gamma Linux First Boot
Comment=Initialize Gamma Linux user configuration
Exec=/usr/local/bin/gamma-firstboot
OnlyShowIn=Enlightenment;
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

# ==========================================================
# Kernel / VM tuning
# ==========================================================

echo "[04] Applying Gamma kernel tuning..."

sudo tee "$CHROOT/etc/sysctl.d/99-gamma.conf" >/dev/null <<EOF
vm.swappiness=$SW
vm.vfs_cache_pressure=$VFS
vm.dirty_ratio=$DIRTY
vm.dirty_background_ratio=5
vm.overcommit_memory=1
EOF

# ==========================================================
# Systemd graphical target
# ==========================================================

echo "[04] Configuring graphical boot..."

sudo ln -sf \
    /lib/systemd/system/graphical.target \
    "$CHROOT/etc/systemd/system/default.target"

# ==========================================================
# Calamares
# ==========================================================

echo
echo "[04] ========================================"
echo "[04] Installing Calamares"
echo "[04] ========================================"

export DEBIAN_FRONTEND=noninteractive

sudo chroot "$CHROOT" apt-get update

# Calamares is available from Universe on Ubuntu Jammy
# and from Debian Bookworm repositories.

sudo chroot "$CHROOT" apt-get install -y \
    calamares \
    calamares-settings-debian \
    rsync \
    cryptsetup \
    policykit-1 \
    pkexec \
    os-prober

# ==========================================================
# Bootloader packages for installed system
# ==========================================================

echo "[04] Installing target bootloader support..."

if [ "$EDITION" = "legacy" ]; then

    sudo chroot "$CHROOT" apt-get install -y \
        grub-pc \
        grub-pc-bin

else

    sudo chroot "$CHROOT" apt-get install -y \
        grub-pc \
        grub-pc-bin \
        grub-efi-amd64 \
        grub-efi-amd64-bin

    # IA32 EFI support when available.
    sudo chroot "$CHROOT" apt-get install -y \
        grub-efi-ia32 \
        grub-efi-ia32-bin || true

fi

# ==========================================================
# Calamares configuration
# ==========================================================

echo "[04] Configuring Calamares..."

CALAMARES="$CHROOT/etc/calamares"

sudo mkdir -p \
    "$CALAMARES/branding/gamma" \
    "$CALAMARES/modules"

# ----------------------------------------------------------
# Keep the package's proven module sequence.
#
# We customize branding and critical Gamma-specific modules
# instead of replacing the entire upstream configuration.
# ----------------------------------------------------------

if [ -f "$CALAMARES/settings.conf" ]; then

    sudo cp \
        "$CALAMARES/settings.conf" \
        "$CALAMARES/settings.conf.gamma-original"

else

    echo "WARNING: Calamares settings.conf was not installed."
fi

# ==========================================================
# Gamma branding
# ==========================================================

echo "[04] Creating Gamma Calamares branding..."

sudo tee "$CALAMARES/branding/gamma/branding.desc" >/dev/null <<EOF
---
componentName: gamma

welcomeStyle: sidebar

strings:
    productName: "Gamma Linux"
    shortProductName: "Gamma"
    version: "2.7"
    shortVersion: "2.7"
    versionedName: "Gamma Linux 2.7"
    shortVersionedName: "Gamma 2.7"
    bootloaderEntryName: "Gamma Linux"

    productUrl: "https://github.com/takismartgamer123-rgb/Gamma-linux"

    productComment: "No PC deserves to die."

    productWelcome: "Welcome to Gamma Linux"

images:
    productLogo: ""
    productIcon: ""
    productWelcome: ""

style:
    SidebarBackground: "#17111f"
    SidebarText: "#ffffff"
    SidebarTextHighlight: "#b36cff"
    SidebarTextHighlightBackground: "#2a1b3d"
EOF

# ==========================================================
# Force Gamma branding in settings
# ==========================================================

if [ -f "$CALAMARES/settings.conf" ]; then

    sudo sed -i \
        's/^branding:.*/branding: gamma/' \
        "$CALAMARES/settings.conf"

fi

# ==========================================================
# UnpackFS configuration
# ==========================================================

echo "[04] Configuring filesystem source..."

sudo tee "$CALAMARES/modules/unpackfs.conf" >/dev/null <<'EOF'
---
unpack:
    - source: "/run/live/medium/casper/filesystem.squashfs"
      sourcefs: "squashfs"
EOF

# Legacy edition uses /live instead of /casper.
if [ "$EDITION" = "legacy" ]; then

    sudo tee "$CALAMARES/modules/unpackfs.conf" >/dev/null <<'EOF'
---
unpack:
    - source: "/run/live/medium/live/filesystem.squashfs"
      sourcefs: "squashfs"
EOF

fi

# ==========================================================
# Mount configuration
# ==========================================================

sudo tee "$CALAMARES/modules/mount.conf" >/dev/null <<'EOF'
---
extraMounts: []
EOF

# ==========================================================
# Display Manager
# ==========================================================

sudo tee "$CALAMARES/modules/displaymanager.conf" >/dev/null <<'EOF'
---
displaymanagers:
    - lightdm

basicSetup: false
EOF

# ==========================================================
# Network configuration
# ==========================================================

sudo tee "$CALAMARES/modules/networkcfg.conf" >/dev/null <<'EOF'
---
backend: NetworkManager
EOF

# ==========================================================
# Locale defaults
# ==========================================================

sudo tee "$CALAMARES/modules/locale.conf" >/dev/null <<'EOF'
---
region: "DZ"
zone: "Africa/Algiers"
EOF

# ==========================================================
# Services
# ==========================================================

sudo tee "$CALAMARES/modules/services-systemd.conf" >/dev/null <<'EOF'
---
services:
    - NetworkManager.service
    - lightdm.service
EOF

# ==========================================================
# Bootloader configuration
# ==========================================================

sudo tee "$CALAMARES/modules/bootloader.conf" >/dev/null <<'EOF'
---
efiBootLoader: "grub"
installDevice: ""
writeBoot: true
EOF

# ==========================================================
# Initramfs
# ==========================================================

if [ -f "$CALAMARES/modules/initramfs.conf" ]; then

    sudo tee "$CALAMARES/modules/initramfs.conf" >/dev/null <<'EOF'
---
kernel: "all"
EOF

fi

# ==========================================================
# Gamma Installer launcher
# ==========================================================

echo "[04] Creating Gamma Installer launcher..."

sudo tee "$CHROOT/usr/share/applications/gamma-installer.desktop" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Install Gamma Linux
GenericName=System Installer
Comment=Install Gamma Linux to your computer
Exec=calamares
Icon=system-software-install
Terminal=false
Categories=System;Settings;
StartupNotify=true
EOF

# ==========================================================
# Installer helper command
# ==========================================================

sudo tee "$CHROOT/usr/local/bin/gamma-installer" >/dev/null <<'EOF'
#!/usr/bin/env bash

exec calamares "$@"
EOF

sudo chmod +x "$CHROOT/usr/local/bin/gamma-installer"

# ==========================================================
# Verify Calamares
# ==========================================================

echo "[04] Verifying Calamares installation..."

sudo chroot "$CHROOT" test -x /usr/bin/calamares

sudo chroot "$CHROOT" calamares --version

if [ ! -f "$CALAMARES/settings.conf" ]; then
    echo "ERROR: Calamares settings.conf missing."
    exit 1
fi

if [ ! -d "$CALAMARES/modules" ]; then
    echo "ERROR: Calamares modules directory missing."
    exit 1
fi

# ==========================================================
# Check important modules
# ==========================================================

echo "[04] Checking Calamares modules..."

REQUIRED_MODULES=(
    partition
    mount
    unpackfs
    machineid
    fstab
    locale
    keyboard
    localecfg
    users
    displaymanager
    networkcfg
    hwclock
    services-systemd
    bootloader
    umount
)

for MODULE in "${REQUIRED_MODULES[@]}"; do

    if ! find "$CHROOT/usr/lib/calamares/modules" \
        -maxdepth 1 \
        -type f \
        -name "${MODULE}.so" \
        -print -quit 2>/dev/null | grep -q .; then

        echo "WARNING: Calamares module not found: $MODULE"

    else

        echo "  OK: $MODULE"

    fi

done

# ==========================================================
# APT cleanup
# ==========================================================

echo "[04] Cleaning package cache..."

sudo chroot "$CHROOT" apt-get autoremove -y || true
sudo chroot "$CHROOT" apt-get clean

sudo rm -rf \
    "$CHROOT/var/lib/apt/lists/"* \
    "$CHROOT/var/cache/apt/archives/"* \
    "$CHROOT/tmp/"* \
    "$CHROOT/var/tmp/"* \
    2>/dev/null || true

# ==========================================================
# Final report
# ==========================================================

echo
echo "=============================================="
echo " Gamma Linux v2.7 SYSTEM CONFIGURATION"
echo "=============================================="
echo " Edition       : $EDITION"
echo " Hostname      : $HOSTNAME"
echo " Desktop       : Enlightenment"
echo " Display       : LightDM"
echo " Network       : NetworkManager"
echo " Installer     : Calamares"
echo " Gamma CC      : enabled"
echo " First Boot    : enabled"
echo " Kernel tuning : enabled"
echo "=============================================="
echo "[04] Configuration completed successfully."
