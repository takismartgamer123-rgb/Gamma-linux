#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

echo "[06] Building EFI boot files ($EDITION)"

ROOT="$(pwd)"
EFI_DIR="$ROOT/iso/EFI/BOOT"
GRUB_DIR="$ROOT/iso/boot/grub"

# ==========================================
# Dependencies
# ==========================================

command -v grub-mkstandalone >/dev/null || {
    echo "ERROR: grub-mkstandalone missing"
    exit 1
}

command -v mcopy >/dev/null || {
    echo "ERROR: mtools missing"
    exit 1
}

command -v mkfs.vfat >/dev/null || {
    echo "ERROR: mkfs.vfat missing"
    exit 1
}

# ==========================================
# Edition / Live layout
# ==========================================

case "$EDITION" in
    legacy)
        LIVE_DIR="live"
        BOOT="boot=live"
        ;;
    pro|lite)
        LIVE_DIR="casper"
        BOOT="boot=casper"
        ;;
    *)
        echo "ERROR: Unknown edition '$EDITION'"
        exit 1
        ;;
esac

# ==========================================
# Prepare
# ==========================================

sudo mkdir -p \
    "$EFI_DIR" \
    "$GRUB_DIR"

sudo rm -f \
    "$EFI_DIR/BOOTX64.EFI" \
    "$EFI_DIR/BOOTIA32.EFI" \
    "$EFI_DIR/grubx64.efi" \
    "$EFI_DIR/grubia32.efi" \
    "$GRUB_DIR/efi.img"

# ==========================================
# GRUB configuration
# ==========================================

sudo tee "$GRUB_DIR/grub.cfg" >/dev/null <<EOF
set timeout=5
set default=0

menuentry "Gamma Linux v2.7 ${EDITION}" {
    linux /${LIVE_DIR}/vmlinuz ${BOOT} quiet splash
    initrd /${LIVE_DIR}/initrd.lz
}

menuentry "Gamma Linux v2.7 ${EDITION} - Safe Graphics" {
    linux /${LIVE_DIR}/vmlinuz ${BOOT} nomodeset
    initrd /${LIVE_DIR}/initrd.lz
}
EOF

# ==========================================
# Build x86_64 EFI
# ==========================================

echo "[06] Creating x86_64 EFI..."

if command -v grub-mkstandalone >/dev/null; then
    grub-mkstandalone \
        -O x86_64-efi \
        --modules="normal linux search search_fs_file fat iso9660" \
        -o "$EFI_DIR/BOOTX64.EFI" \
        "boot/grub/grub.cfg=$GRUB_DIR/grub.cfg"
fi

# ==========================================
# Build IA32 EFI
# ==========================================

echo "[06] Creating IA32 EFI..."

if grub-mkstandalone \
        -O i386-efi \
        --modules="normal linux search search_fs_file fat iso9660" \
        -o "$EFI_DIR/BOOTIA32.EFI" \
        "boot/grub/grub.cfg=$GRUB_DIR/grub.cfg"; then

    echo "[06] IA32 EFI created."

else

    echo "[06] WARNING: IA32 EFI build failed."
    echo "[06] Continuing with x86_64 EFI."

    if [ "$EDITION" = "legacy" ]; then
        echo "[06] ERROR: Legacy edition requires IA32 EFI support."
        exit 1
    fi

fi

# ==========================================
# Verify EFI files
# ==========================================

if [ ! -f "$EFI_DIR/BOOTX64.EFI" ]; then
    echo "ERROR: BOOTX64.EFI missing"
    exit 1
fi

if [ "$EDITION" = "legacy" ] &&
   [ ! -f "$EFI_DIR/BOOTIA32.EFI" ]; then
    echo "ERROR: BOOTIA32.EFI missing for legacy edition"
    exit 1
fi

# ==========================================
# EFI System Partition image
# ==========================================

echo "[06] Creating EFI System Partition image..."

dd if=/dev/zero \
    of="$GRUB_DIR/efi.img" \
    bs=1M \
    count=16 \
    status=none

mkfs.vfat \
    -F 32 \
    "$GRUB_DIR/efi.img" >/dev/null

mmd -i "$GRUB_DIR/efi.img" ::/EFI
mmd -i "$GRUB_DIR/efi.img" ::/EFI/BOOT

# x86_64
mcopy \
    -i "$GRUB_DIR/efi.img" \
    "$EFI_DIR/BOOTX64.EFI" \
    ::/EFI/BOOT/

# IA32
if [ -f "$EFI_DIR/BOOTIA32.EFI" ]; then
    mcopy \
        -i "$GRUB_DIR/efi.img" \
        "$EFI_DIR/BOOTIA32.EFI" \
        ::/EFI/BOOT/
fi

# ==========================================
# Final verification
# ==========================================

echo
echo "========================================="
echo " EFI BUILD COMPLETE"
echo " Edition : $EDITION"
echo " x86_64  : BOOTX64.EFI"
echo " IA32    : $([ -f "$EFI_DIR/BOOTIA32.EFI" ] && echo "BOOTIA32.EFI" || echo "not available")"
echo " ESP     : $GRUB_DIR/efi.img"
echo "========================================="
