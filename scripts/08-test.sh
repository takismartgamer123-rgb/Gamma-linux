#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:-pro}"
ISO="output/gamma-${EDITION}.iso"

echo "[08] Gamma Linux Boot Test ($EDITION)"

# ==========================================
# Check ISO
# ==========================================

if [ ! -f "$ISO" ]; then
    echo "ERROR: ISO not found: $ISO"
    exit 1
fi


# ==========================================
# Detect boot directory
# ==========================================

if [ "$EDITION" = "legacy" ]; then
    LIVE_DIR="live"
else
    LIVE_DIR="casper"
fi


echo "[08] Verifying ISO structure..."


check_file() {
    local FILE="$1"

    xorriso -indev "$ISO" -ls "$FILE" >/dev/null 2>&1 || {
        echo "ERROR: Missing $FILE"
        exit 1
    }
}


check_file "/${LIVE_DIR}/vmlinuz"
check_file "/${LIVE_DIR}/initrd.lz"
check_file "/${LIVE_DIR}/filesystem.squashfs"
check_file "/boot/grub/efi.img"


echo "[08] ISO structure OK."


# ==========================================
# ISO Information
# ==========================================

echo
echo "[08] ISO Details:"
xorriso -indev "$ISO" -pvd_info | grep -E "Volume id|System id" || true


# ==========================================
# QEMU Boot Test
# ==========================================

echo
echo "[08] Starting QEMU..."

timeout 90 qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -cdrom "$ISO" \
    -boot d \
    -serial stdio \
    -display none \
    -no-reboot \
    || true


echo
echo "================================="
echo " Gamma Linux Boot Test Finished"
echo " Edition: $EDITION"
echo " ISO: $ISO"
echo "================================="
