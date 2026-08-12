#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:?Usage: $0 <pro|lite|legacy>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CHROOT="$ROOT/chroot"
ISO_DIR="$ROOT/iso"

case "$EDITION" in
    legacy)
        LIVE_DIR="live"
        ;;
    pro|lite)
        LIVE_DIR="casper"
        ;;
    *)
        echo "ERROR: Unknown edition: $EDITION"
        exit 1
        ;;
esac

TARGET="$ISO_DIR/$LIVE_DIR"
SQUASHFS="$TARGET/filesystem.squashfs"

echo "[05] Building SquashFS ($EDITION)"

# ==========================================================
# Prepare
# ==========================================================

sudo mkdir -p "$TARGET"

sudo rm -f "$SQUASHFS"

# ==========================================================
# Clean runtime state
# ==========================================================

echo "[05] Cleaning temporary state..."

sudo rm -rf \
    "$CHROOT/tmp/"* \
    "$CHROOT/var/tmp/"* \
    "$CHROOT/var/cache/apt/archives/"* \
    2>/dev/null || true

# Do not ship build-machine identity into the Live image.
sudo truncate -s 0 "$CHROOT/etc/machine-id" 2>/dev/null || true
sudo rm -f "$CHROOT/var/lib/dbus/machine-id" 2>/dev/null || true

# Runtime directories are recreated at boot.
sudo rm -rf \
    "$CHROOT/run/"* \
    2>/dev/null || true

# ==========================================================
# Find matching kernel + initramfs
# ==========================================================

echo "[05] Selecting kernel/initramfs pair..."

KERNEL_VERSION="$(
    find "$CHROOT/boot" \
        -maxdepth 1 \
        -type f \
        -name 'vmlinuz-*' \
        -printf '%f\n' |
    sed 's/^vmlinuz-//' |
    sort -V |
    tail -n 1
)"

if [ -z "$KERNEL_VERSION" ]; then
    echo "ERROR: No kernel found."
    exit 1
fi

VMLINUX="$CHROOT/boot/vmlinuz-$KERNEL_VERSION"
INITRD="$CHROOT/boot/initrd.img-$KERNEL_VERSION"

if [ ! -f "$VMLINUX" ]; then
    echo "ERROR: Kernel missing:"
    echo "$VMLINUX"
    exit 1
fi

if [ ! -f "$INITRD" ]; then
    echo "ERROR: Matching initramfs missing:"
    echo "$INITRD"
    exit 1
fi

echo "[05] Kernel : $KERNEL_VERSION"
echo "[05] Initrd : initrd.img-$KERNEL_VERSION"

# ==========================================================
# Verify Casper
# ==========================================================

if [ "$EDITION" != "legacy" ]; then

    echo "[05] Checking Casper support..."

    if ! sudo lsinitramfs "$INITRD" |
        grep -q "scripts/casper"; then

        echo "ERROR: initramfs does not contain Casper."
        echo "Make sure casper is installed in script 02."
        exit 1
    fi

    echo "[05] Casper support: PASS"

fi

# ==========================================================
# Build SquashFS
# ==========================================================

echo "[05] Compressing filesystem..."

sudo mksquashfs \
    "$CHROOT" \
    "$SQUASHFS" \
    -comp zstd \
    -Xcompression-level 19 \
    -b 1M \
    -noappend \
    -e dev \
    -e proc \
    -e sys \
    -e run

# ==========================================================
# Copy kernel + matching initramfs
# ==========================================================

echo "[05] Copying kernel and initramfs..."

sudo cp \
    "$VMLINUX" \
    "$TARGET/vmlinuz"

sudo cp \
    "$INITRD" \
    "$TARGET/initrd.lz"

# ==========================================================
# Verify
# ==========================================================

for FILE in \
    "$TARGET/vmlinuz" \
    "$TARGET/initrd.lz" \
    "$TARGET/filesystem.squashfs"
do
    if [ ! -s "$FILE" ]; then
        echo "ERROR: Missing output: $FILE"
        exit 1
    fi
done

# ==========================================================
# Report
# ==========================================================

SIZE="$(du -h "$SQUASHFS" | awk '{print $1}')"

echo
echo "========================================="
echo " SquashFS completed successfully"
echo " Edition : $EDITION"
echo " Live Dir: $LIVE_DIR"
echo " Kernel  : $KERNEL_VERSION"
echo " Size    : $SIZE"
echo "========================================="
