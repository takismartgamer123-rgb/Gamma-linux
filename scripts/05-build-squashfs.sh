#!/bin/bash
set -e
echo "[05] Building SquashFS"
mkdir -p iso/casper
sudo mksquashfs chroot iso/casper/filesystem.squashfs -comp zstd -Xcompression-level 19 -b 1M -e chroot/dev chroot/proc chroot/sys
sudo cp chroot/boot/vmlinuz-* iso/casper/vmlinuz
sudo cp chroot/boot/initrd.img-* iso/casper/initrd.lz
