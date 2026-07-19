#!/usr/bin/env bash
set -euo pipefail

BOOT_BASE="${1:-casper}"

echo "[06] Building EFI Image"

sudo mkdir -p \
    iso/boot/grub \
    iso/EFI/BOOT

cat > iso/boot/grub/grub.cfg <<EOF
set timeout=5
set default=0

menuentry "Gamma Linux" {
    linux /casper/vmlinuz boot=$BOOT_BASE quiet splash
    initrd /casper/initrd.lz
}
EOF

grub-mkstandalone \
    -O x86_64-efi \
    -o iso/EFI/BOOT/BOOTX64.EFI \
    "boot/grub/grub.cfg=iso/boot/grub/grub.cfg"

cp \
iso/EFI/BOOT/BOOTX64.EFI \
iso/EFI/BOOT/grubx64.efi

dd if=/dev/zero \
of=iso/boot/grub/efi.img \
bs=1M \
count=10

mkfs.vfat iso/boot/grub/efi.img

mmd -i iso/boot/grub/efi.img ::/EFI
mmd -i iso/boot/grub/efi.img ::/EFI/BOOT

mcopy -i iso/boot/grub/efi.img \
iso/EFI/BOOT/* \
::/EFI/BOOT/

echo "[06] EFI image completed."
