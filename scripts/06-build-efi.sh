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

for CMD in grub-mkstandalone mkfs.vfat; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "ERROR: Required command missing: $CMD"
        exit 1
    fi
done

# ==========================================
# Prepare directories
# ==========================================

sudo mkdir -p \
    "$EFI_DIR" \
    "$GRUB_DIR"

sudo chmod -R 755 "$ISO_DIR/EFI" "$ISO_DIR/boot"

sudo rm -f \
    "$EFI_DIR/BOOTX64.EFI" \
    "$EFI_DIR/BOOTIA32.EFI" \
    "$EFI_DIR/grubx64.efi" \
    "$EFI_DIR/grubia32.efi" \
    "$GRUB_DIR/efi.img"

# ==========================================
# Validate kernel + initramfs
# ==========================================

VMLINUX="$ISO_DIR/$LIVE_DIR/vmlinuz"
INITRD="$ISO_DIR/$LIVE_DIR/initrd.lz"

if [ ! -f "$VMLINUX" ]; then
    echo "ERROR: Missing kernel: $VMLINUX"
    exit 1
fi

if [ ! -f "$INITRD" ]; then
    echo "ERROR: Missing initramfs: $INITRD"
    exit 1
fi

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
# Build IA32 EFI
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
        echo "ERROR: IA32 EFI is required for legacy edition."
        exit 1
    fi

    echo "WARNING: Could not build IA32 EFI."
fi

# ==========================================
# Verify EFI executables
# ==========================================

if [ ! -s "$EFI_DIR/BOOTX64.EFI" ]; then
    echo "ERROR: BOOTX64.EFI is missing or empty."
    exit 1
fi

if [ "$EDITION" = "legacy" ] &&
   [ ! -s "$EFI_DIR/BOOTIA32.EFI" ]; then
    echo "ERROR: BOOTIA32.EFI is missing or empty."
    exit 1
fi

# ==========================================
# Create EFI System Partition image
# ==========================================

echo "[06] Creating EFI System Partition image..."

# Increased size from 16MB to 550MB to avoid FAT32 minimum cluster requirements
sudo dd if=/dev/zero \
    of="$GRUB_DIR/efi.img" \
    bs=1M \
    count=550 \
    status=none

# Format with explicit FAT32 parameters
sudo mkfs.vfat \
    -F 32 \
    -s 8 \
    "$GRUB_DIR/efi.img" >/dev/null

# Create EFI directory structure using fuse-based mounting for better reliability
EFI_MOUNT=$(mktemp -d)
trap "sudo umount '$EFI_MOUNT' 2>/dev/null || true; rmdir '$EFI_MOUNT' 2>/dev/null || true" EXIT

# Use loop device to mount and populate
LOOP_DEV=$(sudo losetup -f)
sudo losetup "$LOOP_DEV" "$GRUB_DIR/efi.img"
sudo mount "$LOOP_DEV" "$EFI_MOUNT"

# Create directories
sudo mkdir -p "$EFI_MOUNT/EFI/BOOT"

# Copy EFI binaries
sudo cp "$EFI_DIR/BOOTX64.EFI" "$EFI_MOUNT/EFI/BOOT/"

if [ -f "$EFI_DIR/BOOTIA32.EFI" ]; then
    sudo cp "$EFI_DIR/BOOTIA32.EFI" "$EFI_MOUNT/EFI/BOOT/"
fi

# Sync and unmount
sudo sync
sudo umount "$EFI_MOUNT"
sudo losetup -d "$LOOP_DEV"

# ==========================================
# Final verification
# ==========================================

echo "[06] Verifying EFI image..."

# Verify the image can be mounted
VERIFY_MOUNT=$(mktemp -d)
trap "sudo umount '$VERIFY_MOUNT' 2>/dev/null || true; rmdir '$VERIFY_MOUNT' 2>/dev/null || true" EXIT

VERIFY_LOOP=$(sudo losetup -f)
sudo losetup "$VERIFY_LOOP" "$GRUB_DIR/efi.img"
sudo mount "$VERIFY_LOOP" "$VERIFY_MOUNT"

if [ ! -f "$VERIFY_MOUNT/EFI/BOOT/BOOTX64.EFI" ]; then
    echo "ERROR: BOOTX64.EFI not found in EFI image"
    sudo umount "$VERIFY_MOUNT" || true
    sudo losetup -d "$VERIFY_LOOP" || true
    exit 1
fi

sudo umount "$VERIFY_MOUNT"
sudo losetup -d "$VERIFY_LOOP"

echo
echo "========================================="
echo " EFI BUILD COMPLETE"
echo " Edition : $EDITION"
echo " x86_64  : available"
echo " IA32    : $IA32_STATUS"
echo " ESP     : $GRUB_DIR/efi.img"
echo "========================================="
