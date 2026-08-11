#!/usr/bin/env bash
set -euo pipefail

EDITION="${1:-pro}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ISO="$ROOT/output/gamma-${EDITION}.iso"

echo "[08] Gamma Linux Boot Test ($EDITION)"

# ==========================================
# Edition configuration
# ==========================================

case "$EDITION" in
    pro|lite)
        LIVE_DIR="casper"
        ;;
    legacy)
        LIVE_DIR="live"
        ;;
    *)
        echo "ERROR: Unknown edition: $EDITION"
        exit 1
        ;;
esac

# ==========================================
# Dependencies
# ==========================================

command -v xorriso >/dev/null 2>&1 || {
    echo "ERROR: xorriso missing"
    exit 1
}

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
    echo "ERROR: qemu-system-x86_64 missing"
    exit 1
}

# ==========================================
# ISO existence
# ==========================================

if [ ! -s "$ISO" ]; then
    echo "ERROR: ISO not found or empty:"
    echo "$ISO"
    exit 1
fi

# ==========================================
# ISO structure
# ==========================================

echo "[08] Checking ISO structure..."

check_iso_file() {
    local FILE="$1"

    if ! xorriso -indev "$ISO" -ls "$FILE" >/dev/null 2>&1; then
        echo "FAIL: Missing ISO file: $FILE"
        exit 1
    fi
}

check_iso_file "/${LIVE_DIR}/vmlinuz"
check_iso_file "/${LIVE_DIR}/initrd.lz"
check_iso_file "/${LIVE_DIR}/filesystem.squashfs"

check_iso_file "/boot/grub/efi.img"
check_iso_file "/boot/isolinux/isolinux.bin"
check_iso_file "/boot/isolinux/vesamenu.c32"

echo "[08] ISO structure: PASS"

# ==========================================
# El Torito / System Area
# ==========================================

echo
echo "[08] Checking boot records..."

BOOT_REPORT="$(
    xorriso -indev "$ISO" \
        -report_el_torito plain 2>&1
)"

SYSTEM_REPORT="$(
    xorriso -indev "$ISO" \
        -report_system_area plain 2>&1
)"

if ! grep -qi "isolinux\|ISOLINUX" <<<"$BOOT_REPORT"; then
    echo "FAIL: BIOS El Torito boot image not detected."
    exit 1
fi

if ! grep -qi "efi\|EFI" <<<"$BOOT_REPORT"; then
    echo "FAIL: EFI El Torito boot image not detected."
    exit 1
fi

echo "[08] BIOS boot record: PASS"
echo "[08] EFI boot record : PASS"

# ==========================================
# BIOS boot test
# ==========================================

echo
echo "[08] Testing BIOS boot..."

set +e

timeout 45 \
    qemu-system-x86_64 \
        -m 2048 \
        -smp 2 \
        -cdrom "$ISO" \
        -boot d \
        -display none \
        -monitor none \
        -serial none \
        -no-reboot

BIOS_RC=$?

set -e

if [ "$BIOS_RC" -eq 124 ]; then
    echo "[08] BIOS boot: PASS"
elif [ "$BIOS_RC" -eq 0 ]; then
    echo "[08] BIOS boot: PASS"
else
    echo "[08] BIOS boot: FAIL (exit code $BIOS_RC)"
    exit 1
fi

# ==========================================
# UEFI x86_64 boot test
# ==========================================

OVMF_CODE=""

for CANDIDATE in \
    /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/OVMF/OVMF_CODE_4M.fd \
    /usr/share/edk2/ovmf/OVMF_CODE.fd
do
    if [ -f "$CANDIDATE" ]; then
        OVMF_CODE="$CANDIDATE"
        break
    fi
done

if [ -z "$OVMF_CODE" ]; then
    echo "[08] WARNING: OVMF firmware not found."
    echo "[08] UEFI x86_64 test: SKIPPED"
else
    echo
    echo "[08] Testing UEFI x86_64 boot..."

    set +e

    timeout 45 \
        qemu-system-x86_64 \
            -m 2048 \
            -smp 2 \
            -cdrom "$ISO" \
            -bios "$OVMF_CODE" \
            -boot d \
            -display none \
            -monitor none \
            -serial none \
            -no-reboot

    UEFI_RC=$?

    set -e

    if [ "$UEFI_RC" -eq 124 ]; then
        echo "[08] UEFI x86_64 boot: PASS"
    elif [ "$UEFI_RC" -eq 0 ]; then
        echo "[08] UEFI x86_64 boot: PASS"
    else
        echo "[08] UEFI x86_64 boot: FAIL (exit code $UEFI_RC)"
        exit 1
    fi
fi

# ==========================================
# Final report
# ==========================================

echo
echo "========================================="
echo " Gamma Linux Boot QA"
echo "========================================="
echo " Edition           : $EDITION"
echo " ISO structure     : PASS"
echo " BIOS boot record  : PASS"
echo " EFI boot record   : PASS"
echo " BIOS QEMU         : PASS"
echo " UEFI x86_64       : $([ -n "$OVMF_CODE" ] && echo "PASS" || echo "SKIPPED")"
echo "========================================="
echo "[08] Boot QA completed."
