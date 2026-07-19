#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

echo "[04] Configuring Gamma Linux..."

# ==========================================
# Cleanup mounts on exit
# ==========================================
cleanup() {
    sudo umount chroot/dev 2>/dev/null || true
    sudo umount chroot/proc 2>/dev/null || true
    sudo umount chroot/sys 2>/dev/null || true
}
trap cleanup EXIT

# ==========================================
# Validate edition
# ==========================================
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

# ==========================================
# Create directories
# ==========================================
sudo mkdir -p \
    chroot/etc/lightdm \
    chroot/etc/xdg/autostart \
    chroot/etc/sysctl.d \
    chroot/etc/systemd/system \
    chroot/usr/local/bin

# ==========================================
# LightDM
# ==========================================
sudo tee chroot/etc/lightdm/lightdm.conf >/dev/null <<EOF
[Seat:*]
user-session=enlightenment
greeter-session=lightdm-gtk-greeter
EOF

# ==========================================
# Gamma CC Autostart
# ==========================================
sudo tee chroot/etc/xdg/autostart/gamma-cc.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Gamma Control Center
Exec=gamma-cc
OnlyShowIn=Enlightenment;
X-GNOME-Autostart-enabled=true
EOF

# ==========================================
# Gamma First Boot
# ==========================================
sudo tee chroot/usr/local/bin/gamma-firstboot >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

FLAG="$HOME/.config/gamma/.firstboot_done"

[ -f "$FLAG" ] && exit 0

mkdir -p "$HOME/.config/gamma"
mkdir -p "$HOME/.config/autostart"

echo "Running Gamma Linux First Boot..."

# =====================================
# Future Rocketenment Setup
# =====================================
# Apply Theme
# Apply Wallpaper
# Configure Dock
# Configure Launcher
# Configure Gamma CC

touch "$FLAG"

echo "Gamma First Boot Completed."

exit 0
EOF

sudo chmod +x chroot/usr/local/bin/gamma-firstboot

# ==========================================
# First Boot Autostart
# ==========================================
sudo tee chroot/etc/xdg/autostart/gamma-firstboot.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Gamma Linux First Boot
Exec=/usr/local/bin/gamma-firstboot
OnlyShowIn=Enlightenment;
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

# ==========================================
# Kernel Tweaks
# ==========================================
sudo tee chroot/etc/sysctl.d/99-gamma.conf >/dev/null <<EOF
vm.swappiness=$SW
vm.vfs_cache_pressure=$VFS
vm.dirty_ratio=$DIRTY
vm.dirty_background_ratio=5
vm.overcommit_memory=1
EOF

# ==========================================
# Hostname
# ==========================================
echo "$HOSTNAME" | sudo tee chroot/etc/hostname >/dev/null

# ==========================================
# Default Boot Target
# ==========================================
sudo ln -sf \
/lib/systemd/system/graphical.target \
chroot/etc/systemd/system/default.target

# ==========================================
# Clean APT Cache
# ==========================================
sudo chroot chroot apt-get autoremove -y || true
sudo chroot chroot apt-get clean

echo "[04] Gamma Linux configuration completed successfully."
