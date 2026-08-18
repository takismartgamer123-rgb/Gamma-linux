#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ISO_DIR="$ROOT/iso"
OUTPUT_DIR="$ROOT/output"

ISO="$OUTPUT_DIR/gamma-${EDITION}.iso"
EFI_IMAGE="$ISO_DIR/boot/grub/efi.img"

echo
echo "=========================================================="
echo "          GAMMA LINUX — ISO BEAST BUILDER"
echo "=========================================================="
echo " Edition : $EDITION"
echo " ISO Dir : $ISO_DIR"
echo " Output  : $ISO"
echo "=========================================================="
echo

# ==========================================================
# Edition configuration
# ==========================================================

case "$EDITION" in
    pro|lite)
        LIVE_DIR="casper"
        BOOT="boot=casper"
        ;;
    legacy)
        LIVE_DIR="live"
        BOOT="boot=live"
        ;;
    *)
        echo "ERROR: Unknown edition: $EDITION"
        exit 1
        ;;
esac

# ==========================================================
# Dependencies
# ==========================================================

echo "[07] Checking dependencies..."

for CMD in \
    xorriso \
    cp \
    mkdir \
    rm \
    stat \
    du \
    find \
    grep \
    awk
do
    command -v "$CMD" >/dev/null 2>&1 || {
        echo "ERROR: Required command missing: $CMD"
        exit 1
    }
done

# ==========================================================
# Prepare
# ==========================================================

echo "[07] Preparing ISO tree..."

mkdir -p "$OUTPUT_DIR"

[ -d "$ISO_DIR" ] || {
    echo "ERROR: ISO directory missing:"
    echo "       $ISO_DIR"
    exit 1
}

[ -w "$ISO_DIR" ] || {
    echo "ERROR: ISO directory is not writable:"
    echo "       $ISO_DIR"
    exit 1
}

mkdir -p "$ISO_DIR/boot/isolinux"

rm -f "$ISO"

# ==========================================================
# BIOS boot dependencies
# ==========================================================

echo "[07] Preparing BIOS boot..."

BIOS_FILES=(
    "/usr/lib/ISOLINUX/isolinux.bin"
    "/usr/lib/syslinux/modules/bios/ldlinux.c32"
    "/usr/lib/syslinux/modules/bios/vesamenu.c32"
    "/usr/lib/syslinux/modules/bios/libcom32.c32"
    "/usr/lib/syslinux/modules/bios/libutil.c32"
    "/usr/lib/syslinux/modules/bios/libmenu.c32"
    "/usr/lib/ISOLINUX/isohdpfx.bin"
)

for FILE in "${BIOS_FILES[@]}"; do
    [ -s "$FILE" ] || {
        echo "ERROR: Missing BIOS dependency:"
        echo "       $FILE"
        exit 1
    }
done

cp "/usr/lib/ISOLINUX/isolinux.bin" \
    "$ISO_DIR/boot/isolinux/"

cp "/usr/lib/syslinux/modules/bios/ldlinux.c32" \
    "$ISO_DIR/boot/isolinux/"

cp "/usr/lib/syslinux/modules/bios/vesamenu.c32" \
    "$ISO_DIR/boot/isolinux/"

cp "/usr/lib/syslinux/modules/bios/libcom32.c32" \
    "$ISO_DIR/boot/isolinux/"

cp "/usr/lib/syslinux/modules/bios/libutil.c32" \
    "$ISO_DIR/boot/isolinux/"

cp "/usr/lib/syslinux/modules/bios/libmenu.c32" \
    "$ISO_DIR/boot/isolinux/"

# ==========================================================
# ISOLINUX configuration
# ==========================================================

echo "[07] Writing BIOS boot menu..."

cat > "$ISO_DIR/boot/isolinux/isolinux.cfg" <<EOF
UI vesamenu.c32

MENU TITLE Gamma Linux v2.7 ${EDITION}

TIMEOUT 100
DEFAULT live

LABEL live
    MENU LABEL Start Gamma Linux
    KERNEL /${LIVE_DIR}/vmlinuz
    APPEND initrd=/${LIVE_DIR}/initrd.lz ${BOOT} quiet splash

LABEL safe
    MENU LABEL Gamma Linux - Safe Graphics
    KERNEL /${LIVE_DIR}/vmlinuz
    APPEND initrd=/${LIVE_DIR}/initrd.lz ${BOOT} nomodeset
EOF

# ==========================================================
# Pre-build QA
# ==========================================================

echo
echo "[07] Running pre-build QA..."

REQUIRED_FILES=(
    "$ISO_DIR/$LIVE_DIR/vmlinuz"
    "$ISO_DIR/$LIVE_DIR/initrd.lz"
    "$ISO_DIR/$LIVE_DIR/filesystem.squashfs"

    "$EFI_IMAGE"
    "$ISO_DIR/EFI/BOOT/BOOTX64.EFI"

    "$ISO_DIR/boot/grub/grub.cfg"

    "$ISO_DIR/boot/isolinux/isolinux.bin"
    "$ISO_DIR/boot/isolinux/ldlinux.c32"
    "$ISO_DIR/boot/isolinux/vesamenu.c32"
    "$ISO_DIR/boot/isolinux/libcom32.c32"
    "$ISO_DIR/boot/isolinux/libutil.c32"
    "$ISO_DIR/boot/isolinux/libmenu.c32"
    "$ISO_DIR/boot/isolinux/isolinux.cfg"
)

for FILE in "${REQUIRED_FILES[@]}"; do
    [ -s "$FILE" ] || {
        echo
        echo "ERROR: Missing or empty:"
        echo "       $FILE"
        exit 1
    }
done

# ==========================================================
# Legacy IA32 verification
# ==========================================================

if [ "$EDITION" = "legacy" ]; then

    if [ ! -s "$ISO_DIR/EFI/BOOT/BOOTIA32.EFI" ]; then
        echo
        echo "ERROR: Legacy edition requires:"
        echo "       EFI/BOOT/BOOTIA32.EFI"
        exit 1
    fi

    echo "[07] IA32 UEFI boot: PASS"

fi

# ==========================================================
# EFI image validation
# ==========================================================

EFI_SIZE="$(stat -c '%s' "$EFI_IMAGE")"

if [ "$EFI_SIZE" -gt 33553920 ]; then
    echo
    echo "ERROR: EFI image exceeds El Torito limit."
    echo "       Size: $EFI_SIZE bytes"
    exit 1
fi

echo "[07] EFI image: $EFI_SIZE bytes"

# ==========================================================
# SquashFS sanity check
# ==========================================================

SQUASHFS="$ISO_DIR/$LIVE_DIR/filesystem.squashfs"

echo "[07] Checking SquashFS..."

SQUASH_SIZE="$(stat -c '%s' "$SQUASHFS")"

if [ "$SQUASH_SIZE" -lt 1024 ]; then
    echo "ERROR: filesystem.squashfs is suspiciously small."
    exit 1
fi

echo "[07] SquashFS size: $(du -h "$SQUASHFS" | awk '{print $1}')"
echo "[07] SquashFS: PASS"

echo
echo "[07] Pre-build QA: PASS"

# ==========================================================
# Build ISO
# ==========================================================

echo
echo "=========================================================="
echo "              CREATING HYBRID ISO"
echo "=========================================================="
echo

START_TIME="$(date +%s)"

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -r \
    -J \
    -joliet-long \
    -V "GAMMA_${EDITION^^}" \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -append_partition 2 0xef "$EFI_IMAGE" \
    -o "$ISO" \
    "$ISO_DIR"

END_TIME="$(date +%s)"

BUILD_TIME=$((END_TIME - START_TIME))

# ==========================================================
# Verify ISO
# ==========================================================

[ -s "$ISO" ] || {
    echo "ERROR: ISO was not created."
    exit 1
}

# ==========================================================
# El Torito report
# ==========================================================

echo
echo "[07] ===== El Torito report ====="

xorriso -indev "$ISO" \
    -report_el_torito plain

# ==========================================================
# System Area report
# ==========================================================

echo
echo "[07] ===== System Area report ====="

xorriso -indev "$ISO" \
    -report_system_area plain

# ==========================================================
# Internal ISO QA
# ==========================================================

echo
echo "[07] Verifying ISO contents..."

ISO_FILES=(
    "/${LIVE_DIR}/vmlinuz"
    "/${LIVE_DIR}/initrd.lz"
    "/${LIVE_DIR}/filesystem.squashfs"

    "/boot/grub/efi.img"

    "/boot/isolinux/isolinux.bin"
    "/boot/isolinux/ldlinux.c32"
    "/boot/isolinux/vesamenu.c32"
    "/boot/isolinux/isolinux.cfg"
)

for FILE in "${ISO_FILES[@]}"; do

    if ! xorriso -indev "$ISO" -ls "$FILE" \
        >/dev/null 2>&1
    then
        echo
        echo "ERROR: ISO is missing:"
        echo "       $FILE"
        exit 1
    fi

done

echo "[07] ISO contents: PASS"

# ==========================================================
# ISO size
# ==========================================================

SIZE_BYTES="$(stat -c '%s' "$ISO")"
SIZE_HUMAN="$(du -h "$ISO" | awk '{print $1}')"

# ==========================================================
# Final report
# ==========================================================

echo
echo "=========================================================="
echo "              GAMMA LINUX ISO READY"
echo "=========================================================="
echo
echo " Edition       : $EDITION"
echo " Size          : $SIZE_HUMAN"
echo " Raw Bytes     : $SIZE_BYTES"
echo " File          : $ISO"
echo " BIOS          : ISOLINUX"
echo " UEFI          : GRUB EFI"
echo " Hybrid        : YES"
echo " Build Time    : ${BUILD_TIME}s"
echo
echo " SquashFS:"
echo "   Compression : handled by [05]"
echo "   Algorithm   : XZ"
echo
echo "=========================================================="
echo "              NO PC DESERVES TO DIE"
echo "                 GAMMA LINUX 🟣"
echo "=========================================================="
