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


ISO="output/gamma-${EDITION}.iso"



# ==========================================
# Prepare
# ==========================================

mkdir -p output
mkdir -p iso/boot/isolinux

rm -f "$ISO"



# ==========================================
# Install BIOS boot files
# ==========================================

echo "[07] Preparing BIOS boot"


cp /usr/lib/ISOLINUX/isolinux.bin \
   iso/boot/isolinux/


cp /usr/lib/syslinux/modules/bios/ldlinux.c32 \
   iso/boot/isolinux/


cp /usr/lib/syslinux/modules/bios/vesamenu.c32 \
   iso/boot/isolinux/


cp /usr/lib/syslinux/modules/bios/libcom32.c32 \
   iso/boot/isolinux/


cp /usr/lib/syslinux/modules/bios/libutil.c32 \
   iso/boot/isolinux/


cp /usr/lib/syslinux/modules/bios/libmenu.c32 \
   iso/boot/isolinux/



# ==========================================
# ISOLINUX Config
# ==========================================

cat > iso/boot/isolinux/isolinux.cfg <<EOF
UI vesamenu.c32

MENU TITLE Gamma Linux v2.7 ${EDITION}

TIMEOUT 100
DEFAULT live


LABEL live
    MENU LABEL Start Gamma Linux
    KERNEL /${LIVE_DIR}/vmlinuz
    APPEND initrd=/${LIVE_DIR}/initrd.lz ${BOOT} quiet splash


LABEL safe
    MENU LABEL Gamma Linux Safe Mode
    KERNEL /${LIVE_DIR}/vmlinuz
    APPEND initrd=/${LIVE_DIR}/initrd.lz ${BOOT} nomodeset

EOF



# ==========================================
# QA
# ==========================================

echo "[07] Running ISO QA"


FILES="
iso/${LIVE_DIR}/vmlinuz
iso/${LIVE_DIR}/initrd.lz
iso/${LIVE_DIR}/filesystem.squashfs
iso/boot/grub/efi.img

iso/boot/isolinux/isolinux.bin
iso/boot/isolinux/ldlinux.c32
iso/boot/isolinux/vesamenu.c32
iso/boot/isolinux/libcom32.c32
iso/boot/isolinux/libutil.c32
iso/boot/isolinux/libmenu.c32
"


for FILE in $FILES; do

    if [ ! -f "$FILE" ]; then
        echo "ERROR: Missing $FILE"
        exit 1
    fi

done


echo "[07] QA Passed"



# ==========================================
# Build Hybrid ISO
# ==========================================

echo "[07] Creating Hybrid ISO"


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
    -o "$ISO" \
    iso



SIZE=$(du -h "$ISO" | awk '{print $1}')


echo
echo "======================================="
echo " Gamma Linux ISO READY"
echo " Edition: $EDITION"
echo " Size: $SIZE"
echo " File: $ISO"
echo " BIOS + UEFI Hybrid"
echo "======================================="
