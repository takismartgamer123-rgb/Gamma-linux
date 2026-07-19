#!/bin/bash
set -e
echo "[06] Building EFI Image"
mkdir -p iso/boot/grub iso/EFI/BOOT

cat > iso/boot/grub/grub.cfg <<EOF
set timeout=10
menuentry 'Gamma Linux v2.7' {
  linux /casper/vmlinuz boot=casper quiet splash
  initrd /casper/initrd.lz
}
EOF

grub-mkstandalone -O x86_64-efi -o iso/EFI/BOOT/BOOTX64.EFI "boot/grub/grub.cfg"
cp iso/EFI/BOOT/BOOTX64.EFI iso/EFI/BOOT/grubx64.efi

dd if=/dev/zero of=iso/boot/grub/efi.img bs=1M count=10
mkfs.vfat iso/boot/grub/efi.img
mmd -i iso/boot/grub/efi.img ::/EFI ::/EFI/BOOT
mcopy -i iso/boot/grub/efi.img iso/EFI/BOOT/* ::/EFI/BOOT/
