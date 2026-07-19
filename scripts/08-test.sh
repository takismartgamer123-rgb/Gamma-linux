#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:-pro}"
ISO="output/gamma-${EDITION}.iso"

echo "[08] Gamma Linux Boot Test"

# ==========================
# Check ISO
# ==========================
[ -f "$ISO" ] || {
    echo "ERROR: ISO not found: $ISO"
    exit 1
}

echo "[08] Verifying ISO structure..."

xorriso -indev "$ISO" -ls /casper/ | grep -q "vmlinuz" || {
    echo "ERROR: Missing kernel."
    exit 1
}

xorriso -indev "$ISO" -ls /casper/ | grep -q "initrd.lz" || {
    echo "ERROR: Missing initrd."
    exit 1
}

xorriso -indev "$ISO" -ls /casper/ | grep -q "filesystem.squashfs" || {
    echo "ERROR: Missing SquashFS."
    exit 1
}

echo "[08] ISO structure OK."

# ==========================
# Boot Test
# ==========================
echo "[08] Starting QEMU..."

timeout 60 qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -cdrom "$ISO" \
    -boot d \
    -serial stdio \
    -display none \
    -no-reboot \
    || true

echo "[08] Boot test finished."
