#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ISO_DIR="$ROOT/iso"
EFI_DIR="$ISO_DIR/EFI/BOOT"
GRUB_DIR="$ISO_DIR/boot/grub"

echo "[06] Building EFI boot files ($EDITION)"

# ==========================================
# Validate edition
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

for CMD in grub-mkstandalone mkfs.vfat mcopy mmd; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "ERROR: Required command missing: $CMD"
        exit 1
    fi
done

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
# Validate Live files
# ==========================================

VMLINUX="$ISO_DIR/$LIVE_DIR/vmlinuz"
INITRD="$ISO_DIR/$LIVE_DIR/initrd.lz"

[ -s "$VMLINUX" ] || {
    echo "ERROR: Missing kernel: $VMLINUX"
    exit 1
}

[ -s "$INITRD" ] || {
    echo "ERROR: Missing initramfs: $INITRD"
    exit 1
}

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
# x86_64 EFI
# ==========================================

echo "[06] Building x86_64 EFI..."

sudo grub-mkstandalone \
    -O x86_64-efi \
    --modules="normal linux search search_fs_file fat iso9660" \
    -o "$EFI_DIR/BOOTX64.EFI" \
    "boot/grub/grub.cfg=$GRUB_DIR/grub.cfg"

sudo cp \
    "$EFI_DIR/BOOTX64.EFI" \
    "$EFI_DIR/grubx64.efi"

# ==========================================
# IA32 EFI
# ==========================================

echo "[06] Building IA32 EFI..."

if sudo grub-mkstandalone \
    -O i386-efi \
    --modules="normal linux search search_fs_file fat iso9660" \
    -o "$EFI_DIR/BOOTIA32.EFI" \
    "boot/grub/grub.cfg=$GRUB_DIR/grub.cfg"
then
    sudo cp \
        "$EFI_DIR/BOOTIA32.EFI" \
        "$EFI_DIR/grubia32.efi"

    IA32_STATUS="available"
else
    IA32_STATUS="unavailable"

    if [ "$EDITION" = "legacy" ]; then
        echo "ERROR: IA32 EFI is required for Legacy."
        exit 1
    fi

    echo "WARNING: IA32 EFI unavailable."
fi

# ==========================================
# Verify EFI binaries
# ==========================================

[ -s "$EFI_DIR/BOOTX64.EFI" ] || {
    echo "ERROR: BOOTX64.EFI missing."
    exit 1
}

if [ "$EDITION" = "legacy" ] &&
   [ ! -s "$EFI_DIR/BOOTIA32.EFI" ]; then
    echo "ERROR: BOOTIA32.EFI missing for Legacy."
    exit 1
fi

# ==========================================
# Create EFI System Partition image
# ==========================================
#
# Keep this well below the El Torito EFI
# maximum of 65535 x 512-byte blocks.
#
# 16 MiB = 32768 x 512-byte blocks.
#
# ==========================================

echo "[06] Creating EFI System Partition image..."

sudo dd \
    if=/dev/zero \
    of="$GRUB_DIR/efi.img" \
    bs=1M \
    count=16 \
    status=none

sudo mkfs.vfat \
    -F 32 \
    "$GRUB_DIR/efi.img" >/dev/null

# ==========================================
# Populate EFI image
# ==========================================

EFI_MOUNT="$(mktemp -d)"
LOOP_DEV=""

cleanup_efi() {
    sync || true

    if mountpoint -q "$EFI_MOUNT" 2>/dev/null; then
        sudo umount "$EFI_MOUNT" 2>/dev/null || true
    fi

    if [ -n "$LOOP_DEV" ]; then
        sudo losetup -d "$LOOP_DEV" 2>/dev/null || true
    fi

    rmdir "$EFI_MOUNT" 2>/dev/null || true
}

trap cleanup_efi EXIT

LOOP_DEV="$(sudo losetup --find --show "$GRUB_DIR/efi.img")"

sudo mount "$LOOP_DEV" "$EFI_MOUNT"

sudo mkdir -p \
    "$EFI_MOUNT/EFI/BOOT"

sudo cp \
    "$EFI_DIR/BOOTX64.EFI" \
    "$EFI_MOUNT/EFI/BOOT/"

if [ -s "$EFI_DIR/BOOTIA32.EFI" ]; then
    sudo cp \
        "$EFI_DIR/BOOTIA32.EFI" \
        "$EFI_MOUNT/EFI/BOOT/"
fi

sudo sync

cleanup_efi
trap - EXIT

# ==========================================
# Restore workspace ownership
# ==========================================

sudo chown -R \
    "$(id -u):$(id -g)" \
    "$ISO_DIR"

# ==========================================
# Final report
# ==========================================

EFI_SIZE="$(stat -c '%s' "$GRUB_DIR/efi.img")"

echo
echo "========================================="
echo " EFI BUILD COMPLETE"
echo " Edition : $EDITION"
echo " x86_64  : available"
echo " IA32    : $IA32_STATUS"
echo " ESP     : $GRUB_DIR/efi.img"
echo " ESP size: $EFI_SIZE bytes"
echo "========================================="
