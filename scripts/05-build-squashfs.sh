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

echo
echo "=========================================================="
echo "        GAMMA LINUX — SQUASHFS BEAST BUILDER"
echo "=========================================================="
echo " Edition : $EDITION"
echo " Root    : $CHROOT"
echo " Output  : $SQUASHFS"
echo "=========================================================="
echo

# ==========================================================
# Check required tools
# ==========================================================

for CMD in mksquashfs find sed sort tail du awk sudo lsinitramfs; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $CMD"
        exit 1
    fi
done

# ==========================================================
# Prepare
# ==========================================================

echo "[05] Preparing output directory..."

sudo mkdir -p "$TARGET"

sudo rm -f "$SQUASHFS"

# ==========================================================
# Clean runtime/build state
# ==========================================================

echo "[05] Cleaning temporary state..."

sudo rm -rf \
    "$CHROOT/tmp/"* \
    "$CHROOT/var/tmp/"* \
    "$CHROOT/var/cache/apt/archives/"* \
    2>/dev/null || true

# Remove build-machine identity
echo "[05] Removing machine identity..."

sudo truncate -s 0 "$CHROOT/etc/machine-id" 2>/dev/null || true

sudo rm -f \
    "$CHROOT/var/lib/dbus/machine-id" \
    2>/dev/null || true

# Runtime directories are recreated at boot
echo "[05] Cleaning runtime directories..."

sudo rm -rf \
    "$CHROOT/run/"* \
    2>/dev/null || true

# ==========================================================
# Remove unnecessary package indexes/cache
# ==========================================================

echo "[05] Cleaning package metadata..."

sudo rm -rf \
    "$CHROOT/var/lib/apt/lists/"* \
    2>/dev/null || true

# Remove common leftover logs
echo "[05] Cleaning logs..."

sudo find "$CHROOT/var/log" \
    -type f \
    -exec truncate -s 0 {} \; \
    2>/dev/null || true

# ==========================================================
# Find newest kernel
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

echo
echo "[05] Kernel : $KERNEL_VERSION"
echo "[05] Initrd : initrd.img-$KERNEL_VERSION"
echo

# ==========================================================
# Verify Casper
# ==========================================================

if [ "$EDITION" != "legacy" ]; then

    echo "[05] Checking Casper support..."

    if ! sudo lsinitramfs "$INITRD" |
        grep -q "scripts/casper"; then

        echo
        echo "ERROR: initramfs does not contain Casper."
        echo "Make sure casper is installed in script 02."
        echo

        exit 1
    fi

    echo "[05] Casper support: PASS"

fi

# ==========================================================
# SquashFS — EXTREME COMPRESSION
# ==========================================================

echo
echo "=========================================================="
echo "             EXTREME SQUASHFS COMPRESSION"
echo "=========================================================="
echo
echo "[05] Algorithm : XZ"
echo "[05] Block     : 1 MiB"
echo "[05] Mode      : Maximum compression"
echo "[05] Threads   : Automatic"
echo
echo "WARNING:"
echo "This can be CPU-intensive and MUCH slower than ZSTD."
echo "The goal is minimum filesystem size."
echo

START_TIME="$(date +%s)"

sudo mksquashfs \
    "$CHROOT" \
    "$SQUASHFS" \
    -comp xz \
    -b 1M \
    -noappend \
    -no-xattrs \
    -no-fragments \
    -e dev \
    -e proc \
    -e sys \
    -e run

END_TIME="$(date +%s)"

BUILD_TIME=$((END_TIME - START_TIME))

# ==========================================================
# Copy kernel + initramfs
# ==========================================================

echo
echo "[05] Copying kernel..."

sudo cp \
    "$VMLINUX" \
    "$TARGET/vmlinuz"

echo "[05] Copying initramfs..."

sudo cp \
    "$INITRD" \
    "$TARGET/initrd.lz"

# ==========================================================
# Verify output
# ==========================================================

echo
echo "[05] Verifying output..."

for FILE in \
    "$TARGET/vmlinuz" \
    "$TARGET/initrd.lz" \
    "$TARGET/filesystem.squashfs"
do
    if [ ! -s "$FILE" ]; then
        echo
        echo "ERROR: Missing or empty output:"
        echo "$FILE"
        exit 1
    fi
done

# ==========================================================
# Size report
# ==========================================================

SQUASH_SIZE_BYTES="$(stat -c '%s' "$SQUASHFS")"

SQUASH_SIZE="$(du -h "$SQUASHFS" | awk '{print $1}')"

echo
echo "=========================================================="
echo "          GAMMA SQUASHFS BEAST COMPLETED"
echo "=========================================================="
echo
echo " Edition       : $EDITION"
echo " Live Dir      : $LIVE_DIR"
echo " Kernel        : $KERNEL_VERSION"
echo " Compression   : XZ"
echo " Block Size    : 1 MiB"
echo " SquashFS Size : $SQUASH_SIZE"
echo " Raw Bytes     : $SQUASH_SIZE_BYTES"
echo " Build Time    : ${BUILD_TIME}s"
echo
echo " Output:"
echo " $SQUASHFS"
echo
echo "=========================================================="
echo "                 GAMMA LINUX 🟣"
echo "            No PC Deserves To Die"
echo "=========================================================="
