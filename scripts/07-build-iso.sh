#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

echo "[07] Building Gamma Linux ISO ($EDITION)"

# ==========================
# Boot mode
# ==========================
if [ "$EDITION" = "legacy" ]; then
    BOOT="live"
else
    BOOT="casper"
fi

# ==========================
# Directories
# ==========================
mkdir -p output
mkdir -p iso/boot/isolinux

# ==========================
# ISOLINUX Config
# ==========================
cat > iso/boot/isolinux/isolinux.cfg <<EOF
UI vesamenu.c32

MENU TITLE Gamma Linux v2.7 ($EDITION)

TIMEOUT 100
DEFAULT live

LABEL live
    MENU LABEL ^Start Gamma Linux
    KERNEL /casper/vmlinuz
    APPEND initrd=/casper/initrd.lz boot=$BOOT quiet splash

LABEL safe
    MENU LABEL Start Gamma Linux (Safe Mode)
    KERNEL /casper/vmlinuz
    APPEND initrd=/casper/initrd.lz boot=$BOOT nomodeset
EOF

# ==========================
# Quality Assurance
# ==========================
echo "[07] Running QA..."

[ -f iso/casper/vmlinuz ] || { echo "ERROR: Missing kernel."; exit 1; }
[ -f iso/casper/initrd.lz ] || { echo "ERROR: Missing initrd."; exit 1; }
[ -f iso/casper/filesystem.squashfs ] || { echo "ERROR: Missing filesystem.squashfs."; exit 1; }
[ -f iso/boot/grub/efi.img ] || { echo "ERROR: Missing EFI image."; exit 1; }

echo "[07] QA Passed."

# ==========================
# Build ISO
# ==========================
echo "[07] Creating ISO..."

xorriso -as mkisofs \
    -iso-level 3 \
    -r \
    -V "GAMMA_${EDITION^^}" \
    -J \
    -joliet-long \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -o "output/gamma-${EDITION}.iso" \
    iso

echo
echo "======================================="
echo " Gamma Linux ISO Created Successfully!"
echo "======================================="
echo
echo "ISO:"
echo "output/gamma-${EDITION}.iso"
echo
