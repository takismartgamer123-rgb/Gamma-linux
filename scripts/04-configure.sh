#!/usr/bin/env bash
set -euo pipefail

EDITION="$1"

echo "[04] Configuring Gamma Linux..."

# ==========================
# Cleanup mounts on exit
# ==========================
trap 'sudo umount chroot/dev 2>/dev/null || true
sudo umount chroot/proc 2>/dev/null || true
sudo umount chroot/sys 2>/dev/null || true' EXIT

# ==========================
# Create directories
# ==========================
sudo mkdir -p \
    chroot/etc/lightdm \
    chroot/etc/xdg/autostart \
    chroot/etc/sysctl.d \
    chroot/etc/skel \
    chroot/usr/local/bin

# ==========================
# LightDM
# ==========================
sudo tee chroot/etc/lightdm/lightdm.conf >/dev/null <<EOF
[Seat:*]
user-session=enlightenment
greeter-session=lightdm-gtk-greeter
EOF

# ==========================
# Gamma CC Autostart
# ==========================
sudo tee chroot/etc/xdg/autostart/gamma-cc.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Gamma Control Center
Exec=gamma-cc
OnlyShowIn=Enlightenment;
X-GNOME-Autostart-enabled=true
EOF

# ==========================
# Gamma First Boot Script
# ==========================
sudo tee chroot/usr/local/bin/gamma-firstboot >/dev/null <<'EOF'
#!/usr/bin/env bash
set -e

FLAG="$HOME/.config/gamma/.firstboot_done"

if [ -f "$FLAG" ]; then
    exit 0
fi

mkdir -p "$HOME/.config/gamma"

echo "Running Gamma Linux First Boot..."

# ==========================
# TODO (Rocketenment)
# ==========================
# Apply Rocketenment Theme
# Apply Wallpaper
# Configure Dock
# Configure Launcher
# Configure Gamma CC

touch "$FLAG"

echo "First Boot Finished."

exit 0
EOF

sudo chmod +x chroot/usr/local/bin/gamma-firstboot

# ==========================
# First Boot Autostart
# ==========================
sudo tee chroot/etc/xdg/autostart/gamma-firstboot.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Gamma First Boot
Exec=/usr/local/bin/gamma-firstboot
OnlyShowIn=Enlightenment;
X-GNOME-Autostart-enabled=true
EOF

# ==========================
# Kernel Tweaks
# ==========================
case "$EDITION" in
    pro)
        SW=80
        VFS=50
        DIRTY=20
        ;;
    lite)
        SW=100
        VFS=100
        DIRTY=10
        ;;
    legacy)
        SW=100
        VFS=150
        DIRTY=5
        ;;
esac

sudo tee chroot/etc/sysctl.d/99-gamma.conf >/dev/null <<EOF
vm.swappiness=$SW
vm.vfs_cache_pressure=$VFS
vm.dirty_ratio=$DIRTY
vm.overcommit_memory=1
EOF

# ==========================
# Hostname
# ==========================
echo "gamma-$EDITION" | sudo tee chroot/etc/hostname >/dev/null

# ==========================
# Default Target
# ==========================
sudo chroot chroot systemctl set-default graphical.target

# ==========================
# Cleanup APT
# ==========================
sudo chroot chroot apt-get clean

echo "[04] Configuration completed successfully."
