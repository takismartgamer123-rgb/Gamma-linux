#!/usr/bin/env bash
set -euo pipefail

echo "[06] Building EFI Image"

# ==========================================
# Check dependencies
# ==========================================
command -v grub-mkstandalone >/dev/null || {
    echo "ERROR: grub-mkstandalone missing"
    exit 1
}

command -v mcopy >/dev/null || {
    echo "ERROR: mtools missing"
    exit 1
}

# ==========================================
# Prepare directories
# ==========================================
sudo mkdir -p \
    iso/boot/grub \
    iso/EFI/BOOT


# ==========================================
# GRUB Config
# ==========================================
cat > iso/boot/grub/grub.cfg <<'EOF'
set timeout=5
set default=0

menuentry "Gamma Linux v2.7" {

    linux /casper/vmlinuz \
    boot=casper \
    quiet splash

    initrd /casper/initrd.lz
}
EOF


# ==========================================
# Build EFI executable
# ==========================================
echo "[06] Creating GRUB EFI..."

grub-mkstandalone \
    -O x86_64-efi \
    --modules="normal linux search search_fs_file fat iso9660" \
    -o iso/EFI/BOOT/BOOTX64.EFI \
    "boot/grub/grub.cfg=$PWD/iso/boot/grub/grub.cfg"


cp \
iso/EFI/BOOT/BOOTX64.EFI \
iso/EFI/BOOT/grubx64.efi


# ==========================================
# Create EFI partition image
# ==========================================
echo "[06] Creating EFI partition..."

rm -f iso/boot/grub/efi.img

dd if=/dev/zero \
    of=iso/boot/grub/efi.img \
    bs=1M \
    count=10 \
    status=none

mkfs.vfat \
    iso/boot/grub/efi.img


mmd -i iso/boot/grub/efi.img ::/EFI
mmd -i iso/boot/grub/efi.img ::/EFI/BOOT


mcopy \
    -i iso/boot/grub/efi.img \
    iso/EFI/BOOT/BOOTX64.EFI \
    ::/EFI/BOOT/


echo "[06] EFI image completed successfully."
