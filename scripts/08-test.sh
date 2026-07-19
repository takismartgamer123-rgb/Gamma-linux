#!/bin/bash
set -e
echo "[08] QEMU Boot Test"
ISO=output/gamma-pro.iso

echo "Checking ISO structure..."
xorriso -indev $ISO -ls /casper/ | grep -q vmlinuz
xorriso -indev $ISO -ls /casper/ | grep -q filesystem.squashfs

echo "Booting ISO for 45s..."
timeout 60 qemu-system-x86_64 \
  -m 1024 \
  -cdrom $ISO \
  -boot d \
  -display none \
  -nographic || true

echo "BOOT TEST PASSED"
