#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ISO_DIR="$ROOT/iso"
OUTPUT_DIR="$ROOT/output"

ISO="$OUTPUT_DIR/gamma-${EDITION}.iso"

echo "[07] Building Gamma Linux ISO ($EDITION)"

# ==========================================
# Edition configuration
# ==========================================

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

# ==========================================
# Dependencies
# ==========================================

for CMD in xorriso cp; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "ERROR: Required command missing: $CMD"
        exit 1
    fi
done

# ==========================================
# Prepare
# ==========================================

# Create the required directories as the invoking user (avoid sudo inside scripts)
mkdir -p \
    "$OUTPUT_DIR" \
    "$ISO_DIR/boot/isolinux"

# Ensure files and directories under ISO_DIR are readable and directories are searchable/executable
# but do not change ownership — this lets non-root runs of the script (and subsequent cp/cat)
# write files into the directories.
if [ -d "$ISO_DIR" ]; then
    chmod -R a+rX "$ISO_DIR" || true
fi

rm -f "$ISO"

# ==========================================
# BIOS boot files
# ==========================================

echo "[07] Preparing BIOS boot..."

BIOS_FILES=(
    "/usr/lib/ISOLINUX/isolinux.bin"
    "/usr/lib/syslinux/modules/bios/ldlinux.c32"
    "/usr/lib/syslinux/modules/bios/vesamenu.c32"
    "/usr/lib/syslinux/modules/bios/libcom32.c32"
    "/usr/lib/syslinux/modules/bios/libutil.c32"
    "/usr/lib/syslinux/modules/bios/libmenu.c32"
)

for FILE in "${BIOS_FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo "ERROR: BIOS boot file missing: $FILE"
        exit 1
    fi
done

cp /usr/lib/ISOLINUX/isolinux.bin \
    "$ISO_DIR/boot/isolinux/"

cp /usr/lib/syslinux/modules/bios/ldlinux.c32 \
    "$ISO_DIR/boot/isolinux/"

cp /usr/lib/syslinux/modules/bios/vesamenu.c32 \
    "$ISO_DIR/boot/isolinux/"

cp /usr/lib/syslinux/modules/bios/libcom32.c32 \
    "$ISO_DIR/boot/isolinux/"

cp /usr/lib/syslinux/modules/bios/libutil.c32 \
    "$ISO_DIR/boot/isolinux/"

cp /usr/lib/syslinux/modules/bios/libmenu.c32 \
    "$ISO_DIR/boot/isolinux/"

# ==========================================
# ISOLINUX configuration
# ==========================================

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

# ==========================================
# Pre-build QA
# ==========================================

echo "[07] Running pre-build QA..."

REQUIRED_FILES=(
    "$ISO_DIR/$LIVE_DIR/vmlinuz"
    "$ISO_DIR/$LIVE_DIR/initrd.lz"
    "$ISO_DIR/$LIVE_DIR/filesystem.squashfs"
    "$ISO_DIR/boot/grub/efi.img"
    "$ISO_DIR/EFI/BOOT/BOOTX64.EFI"
    "$ISO_DIR/boot/isolinux/isolinux.bin"
    "$ISO_DIR/boot/isolinux/ldlinux.c32"
    "$ISO_DIR/boot/isolinux/vesamenu.c32"
    "$ISO_DIR/boot/isolinux/libcom32.c32"
    "$ISO_DIR/boot/isolinux/libutil.c32"
    "$ISO_DIR/boot/isolinux/libmenu.c32"
    "$ISO_DIR/boot/isolinux/isolinux.cfg"
    "$ISO_DIR/boot/grub/grub.cfg"
)

for FILE in "${REQUIRED_FILES[@]}"; do
    if [ ! -s "$FILE" ]; then
        echo "ERROR: Missing or empty file:"
        echo "       $FILE"
        exit 1
    fi
done

if [ "$EDITION" = "legacy" ] &&
   [ ! -s "$ISO_DIR/EFI/BOOT/BOOTIA32.EFI" ]; then
    echo "ERROR: Legacy edition requires BOOTIA32.EFI."
    exit 1
fi

echo "[07] Pre-build QA passed."

# ==========================================
# Build ISO
# ==========================================

echo "[07] Creating Hybrid ISO..."

xorriso -as mkisofs \
    -iso-level 3 \
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
    -append_partition 2 0xef boot/grub/efi.img \
    -o "$ISO" \
    "$ISO_DIR"

# ==========================================
# Verify ISO exists
# ==========================================

if [ ! -s "$ISO" ]; then
    echo "ERROR: ISO was not created."
    exit 1
fi

# ==========================================
# ISO inspection
# ==========================================

echo
echo "[07] ISO El Torito report..."
xorriso -indev "$ISO" \
    -report_el_torito plain

echo
echo "[07] ISO system-area report..."
xorriso -indev "$ISO" \
    -report_system_area plain

# ==========================================
# ISO internal QA
# ==========================================

echo
echo "[07] Verifying ISO contents..."

ISO_FILES=(
    "/${LIVE_DIR}/vmlinuz"
    "/${LIVE_DIR}/initrd.lz"
    "/${LIVE_DIR}/filesystem.squashfs"
    "/boot/grub/efi.img"
    "/boot/isolinux/isolinux.bin"
    "/boot/isolinux/vesamenu.c32"
    "/boot/isolinux/isolinux.cfg"
)

for FILE in "${ISO_FILES[@]}"; do
    if ! xorriso -indev "$ISO" -ls "$FILE" >/dev/null 2>&1; then
        echo "ERROR: ISO is missing: $FILE"
        exit 1
    fi
done

echo "[07] ISO contents verified."

# ==========================================
# Report
# ==========================================

SIZE=$(du -h "$ISO" | awk '{print $1}')

echo
echo "======================================="
echo " Gamma Linux ISO READY"
echo " Edition : $EDITION"
echo " Size    : $SIZE"
echo " File    : $ISO"
echo " BIOS    : ISOLINUX"
echo " UEFI    : EFI System Partition"
echo " Hybrid  : yes"
echo "======================================="
