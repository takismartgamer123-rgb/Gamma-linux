#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROOT="$ROOT/chroot"

echo "[04] Configuring Gamma Linux ($EDITION)"

# ==========================================================
# Cleanup
# ==========================================================

cleanup() {
    sync || true

    sudo umount -R "$CHROOT/dev" 2>/dev/null || true
    sudo umount "$CHROOT/proc" 2>/dev/null || true
    sudo umount "$CHROOT/sys" 2>/dev/null || true
    sudo umount -R "$CHROOT/run" 2>/dev/null || true
}

trap cleanup EXIT

# ==========================================================
# Edition tuning
# ==========================================================

case "$EDITION" in

    pro)
        SWAPPINESS=80
        VFS_CACHE=50
        DIRTY_RATIO=20
        ZRAM_PERCENT=50
        HOSTNAME="gamma-pro"
        ;;

    lite)
        SWAPPINESS=100
        VFS_CACHE=100
        DIRTY_RATIO=10
        ZRAM_PERCENT=75
        HOSTNAME="gamma-lite"
        ;;

    legacy)
        SWAPPINESS=100
        VFS_CACHE=100
        DIRTY_RATIO=5
        ZRAM_PERCENT=100
        HOSTNAME="gamma-legacy"
        ;;

    *)
        echo "ERROR: Unknown edition '$EDITION'"
        exit 1
        ;;

esac

# ==========================================================
# Directories
# ==========================================================

sudo mkdir -p \
    "$CHROOT/etc/lightdm" \
    "$CHROOT/etc/xdg/autostart" \
    "$CHROOT/etc/sysctl.d" \
    "$CHROOT/etc/systemd/system" \
    "$CHROOT/usr/local/bin" \
    "$CHROOT/usr/share/applications" \
    "$CHROOT/etc/calamares/branding/gamma"

# ==========================================================
# Gamma identity
# ==========================================================

sudo tee "$CHROOT/etc/gamma-release" >/dev/null <<EOF
GAMMA_NAME="Gamma Linux"
GAMMA_EDITION="$EDITION"
GAMMA_VERSION="2.7"
CODENAME="Warden"
EOF

sudo tee "$CHROOT/etc/motd" >/dev/null <<'EOF'

========================================
        Gamma Linux
        No PC deserves to die.
========================================

EOF

# Keep real Ubuntu/Debian /etc/os-release untouched.
# Some system tools and installers use it.

# ==========================================================
# Hostname default
# ==========================================================

echo "$HOSTNAME" | sudo tee "$CHROOT/etc/hostname" >/dev/null

# ==========================================================
# LightDM
# ==========================================================

sudo tee "$CHROOT/etc/lightdm/lightdm.conf" >/dev/null <<EOF
[Seat:*]
user-session=enlightenment
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
greeter-show-manual-login=true
allow-guest=false
EOF

# ==========================================================
# Gamma first boot
# ==========================================================

sudo tee "$CHROOT/usr/local/bin/gamma-firstboot" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

FLAG="$HOME/.config/gamma/.firstboot_done"

if [ -f "$FLAG" ]; then
    exit 0
fi

mkdir -p "$HOME/.config/gamma"

# v2.7 intentionally keeps Enlightenment mostly stock.
# Gamma-specific first-boot customization can be expanded
# later without changing the base desktop.

touch "$FLAG"
EOF

sudo chmod +x "$CHROOT/usr/local/bin/gamma-firstboot"

sudo tee "$CHROOT/etc/xdg/autostart/gamma-firstboot.desktop" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Gamma Linux First Boot
Comment=Initialize Gamma Linux
Exec=/usr/local/bin/gamma-firstboot
OnlyShowIn=Enlightenment;
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

# ==========================================================
# Gamma installer launcher
# ==========================================================

sudo tee "$CHROOT/usr/local/bin/gamma-installer" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export QT_AUTO_SCREEN_SCALE_FACTOR=1

cleanup_xhost() {
    if command -v xhost >/dev/null 2>&1; then
        xhost -si:localuser:root >/dev/null 2>&1 || true
    fi
}

trap cleanup_xhost EXIT

if command -v xhost >/dev/null 2>&1; then
    xhost +si:localuser:root >/dev/null 2>&1 || true
fi

exec pkexec env \
    DISPLAY="${DISPLAY:-}" \
    XAUTHORITY="${XAUTHORITY:-}" \
    QT_AUTO_SCREEN_SCALE_FACTOR=1 \
    calamares "$@"
EOF

sudo chmod +x "$CHROOT/usr/local/bin/gamma-installer"

sudo tee "$CHROOT/usr/share/applications/gamma-installer.desktop" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Install Gamma Linux
GenericName=System Installer
Comment=Install Gamma Linux to your computer
Keywords=gamma;system;installer;
TryExec=gamma-installer
Exec=gamma-installer
Icon=calamares
Terminal=false
StartupNotify=true
Categories=System;Settings;
EOF

# ==========================================================
# ZRAM — Gamma pre-tuned
# ==========================================================

echo "[04] Configuring Gamma pre-tuned ZRAM..."

sudo tee "$CHROOT/etc/default/zramswap" >/dev/null <<EOF
# Gamma Linux 2.7 pre-tuned ZRAM configuration

ALGO=zstd
PERCENT=$ZRAM_PERCENT
EOF

# Make sure the service is enabled for the installed system.
sudo chroot "$CHROOT" systemctl enable zramswap.service \
    2>/dev/null || true

# ==========================================================
# Kernel tuning
# ==========================================================

sudo tee "$CHROOT/etc/sysctl.d/99-gamma.conf" >/dev/null <<EOF
vm.swappiness=$SWAPPINESS
vm.vfs_cache_pressure=$VFS_CACHE
vm.dirty_ratio=$DIRTY_RATIO
vm.dirty_background_ratio=5
vm.page-cluster=0
EOF

# Deliberately do not force:
# vm.overcommit_memory=1
#
# It is not required for ZRAM itself.

# ==========================================================
# Graphical target
# ==========================================================

sudo ln -sf \
    /lib/systemd/system/graphical.target \
    "$CHROOT/etc/systemd/system/default.target"

# ==========================================================
# Calamares verification and setup
# ==========================================================

echo "[04] Verifying Calamares..."

if [ ! -x "$CHROOT/usr/bin/calamares" ]; then
    echo "ERROR: Calamares is not installed."
    exit 1
fi

# ==========================================================
# Gamma Calamares settings
# ==========================================================

CAL_ROOT="$CHROOT/etc/calamares"

sudo mkdir -p \
    "$CAL_ROOT/branding/gamma"

# Find and copy the Calamares settings file from the system
# It may be in different locations depending on the distribution
CALAMARES_SETTINGS=""

if [ -f "$CHROOT/usr/share/calamares/settings.conf" ]; then
    CALAMARES_SETTINGS="$CHROOT/usr/share/calamares/settings.conf"
elif [ -f "$CHROOT/etc/calamares/settings.conf" ]; then
    CALAMARES_SETTINGS="$CHROOT/etc/calamares/settings.conf"
fi

if [ -z "$CALAMARES_SETTINGS" ]; then
    echo "[04] WARNING: Calamares settings.conf not found in standard locations."
    echo "[04] Creating minimal Calamares settings.conf..."
    
    # Create a minimal Calamares settings file if none exists
    sudo tee "$CAL_ROOT/settings.conf" >/dev/null <<'CALEOF'
---
branding: gamma

sequence:
  - show:
    - welcome
    - locale
    - keyboard
    - partition
    - summary
  - exec:
    - partition
    - mount
    - unpackfs
    - machineid
    - fstab
    - locale
    - keyboard
    - localecfg
    - users
    - displaymanager
    - hwclock
    - grub
    - bootloader
    - umount
  - show:
    - finished

modules:
  welcome: null
  locale: null
  keyboard: null
  partition: null
  summary: null
  unpackfs: null
  machineid: null
  fstab: null
  localecfg: null
  users: null
  displaymanager:
    displaymanagers:
      - lightdm
  hwclock:
    hwclock_backend: auto
  grub: null
  bootloader: null
  finished: null
CALEOF
else
    # Copy and customize the existing settings
    sudo cp "$CALAMARES_SETTINGS" "$CAL_ROOT/settings.conf"
    
    # Use Gamma branding while retaining the upstream module order.
    sudo sed -i \
        -E 's/^[[:space:]]*branding:[[:space:]]*.*/branding: gamma/' \
        "$CAL_ROOT/settings.conf"
fi

# ==========================================================
# Gamma Calamares branding
# ==========================================================

sudo tee "$CAL_ROOT/branding/gamma/branding.desc" >/dev/null <<EOF
---
componentName: gamma

strings:
    productName: "Gamma Linux"
    shortProductName: "Gamma"
    version: "2.7"
    shortVersion: "2.7"
    versionedName: "Gamma Linux 2.7"
    shortVersionedName: "Gamma 2.7"
    bootloaderEntryName: "Gamma Linux"
    productComment: "No PC deserves to die."
    productWelcome: "Welcome to Gamma Linux"
    productUrl: "https://github.com/takismartgamer123-rgb/Gamma-linux"
EOF

# ==========================================================
# Installer configuration sanity check
# ==========================================================

echo "[04] Calamares configuration:"
grep -E '^[[:space:]]*branding:' \
    "$CAL_ROOT/settings.conf" || true

# ==========================================================
# ZRAM sanity check
# ==========================================================

echo "[04] ZRAM configuration:"
cat "$CHROOT/etc/default/zramswap"

# ==========================================================
# Clean package cache
# ==========================================================

sudo chroot "$CHROOT" apt-get clean

sudo rm -rf \
    "$CHROOT/var/cache/apt/archives/"* \
    "$CHROOT/tmp/"* \
    "$CHROOT/var/tmp/"* \
    2>/dev/null || true

echo "[04] Gamma configuration completed."
