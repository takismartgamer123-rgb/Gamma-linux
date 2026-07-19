#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

echo "[07] Building Gamma Linux ISO ($EDITION)"

# ==========================================
# Boot configuration
# ==========================================

if [ "$EDITION" = "legacy" ]; then
    LIVE_DIR="live"
    BOOT="boot=live"
else
    LIVE_DIR="casper"
    BOOT="boot=casper"
fi


# ==========================================
# Prepare
# ==========================================

mkdir -p output
mkdir -p iso/boot/isolinux

rm -f "output/gamma-${EDITION}.iso"


# ==========================================
# ISOLINUX
# ==========================================

cat > iso/boot/isolinux/isolinux.cfg <<EOF
UI vesamenu.c32

MENU TITLE Gamma Linux v2.7 ${EDITION}

TIMEOUT 100
DEFAULT live


LABEL live
    MENU LABEL ^Start Gamma Linux
    KERNEL /${LIVE_DIR}/vmlinuz
    APPEND initrd=/${LIVE_DIR}/initrd.lz ${BOOT} quiet splash


LABEL safe
    MENU LABEL Start Gamma Linux (Safe Mode)
    KERNEL /${LIVE_DIR}/vmlinuz
    APPEND initrd=/${LIVE_DIR}/initrd.lz ${BOOT} nomodeset
EOF


# ==========================================
# QA
# ==========================================

echo "[07] Running ISO QA..."

FILES="
iso/${LIVE_DIR}/vmlinuz
iso/${LIVE_DIR}/initrd.lz
iso/${LIVE_DIR}/filesystem.squashfs
iso/boot/grub/efi.img
iso/boot/isolinux/isolinux.bin
iso/boot/isolinux/vesamenu.c32
"

for FILE in $FILES; do
    if [ ! -f "$FILE" ]; then
        echo "ERROR: Missing $FILE"
        exit 1
    fi
done

echo "[07] QA Passed."


# ==========================================
# Build ISO
# ==========================================

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


# ==========================================
# Result
# ==========================================

SIZE=$(du -h "output/gamma-${EDITION}.iso" | awk '{print $1}')

echo
echo "======================================="
echo " Gamma Linux ISO READY"
echo " Edition: $EDITION"
echo " Size: $SIZE"
echo " File: output/gamma-${EDITION}.iso"
echo "======================================="
