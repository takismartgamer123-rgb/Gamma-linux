#!/bin/bash
set -e
EDITION=$1
echo "[04] Configuring System"

# LightDM + E17 + Theme
echo -e "[Seat:*]\nuser-session=enlightenment\ngreeter-session=lightdm-gtk-greeter" | sudo tee chroot/etc/lightdm/lightdm.conf
mkdir -p chroot/etc/xdg/autostart chroot/etc/skel/.e/e/config/standard
echo -e "[Desktop Entry]\nType=Application\nName=Gamma CC\nExec=gamma-cc" | sudo tee chroot/etc/xdg/autostart/gamma-cc.desktop
echo 'theme: "gamma-ios"' | sudo tee chroot/etc/skel/.e/e/config/standard/e.cfg

# Sysctl
if [ "$EDITION" = "pro" ]; then SW=80; VFS=50; else SW=100; VFS=100; fi
echo -e "vm.swappiness=$SW\nvm.vfs_cache_pressure=$VFS\nvm.overcommit_memory=1" | sudo tee chroot/etc/sysctl.d/99-gamma.conf
echo "gamma-$EDITION" | sudo tee chroot/etc/hostname

sudo chroot chroot systemctl set-default graphical.target
sudo chroot chroot apt-get clean
sudo umount chroot/dev chroot/proc chroot/sys || true
