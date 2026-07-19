#!/bin/bash
set -e
EDITION=$1
echo "[07] Building ISO"

mkdir -p iso/boot/isolinux
cat > iso/boot/isolinux/isolinux.cfg <<EOF
UI vesamenu.c32
MENU TITLE Gamma Linux v2.7 $EDITION
TIMEOUT 100
LABEL live
  MENU LABEL ^Start Gamma Linux
  KERNEL /casper/vmlinuz
  APPEND initrd=/casper/initrd.lz boot=casper quiet splash
EOF

# فحص الجودة
echo "[QA] Verifying boot files"
[ -f iso/casper/vmlinuz ] || exit 1
[ -f iso/casper/filesystem.squashfs ] || exit 1
[ -f iso/boot/grub/efi.img ] || exit 1

xorriso -as mkisofs -iso-level 3 -r -V "GAMMA_$EDITION" -J -joliet-long \
-b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table \
-eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat \
-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin -o output/gamma-$EDITION.iso iso/
