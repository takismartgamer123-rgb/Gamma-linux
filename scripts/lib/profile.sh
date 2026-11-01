#!/usr/bin/env bash
# Shared edition profile loader for Gamma's manual Debian chroot/ISO builder.
# Profiles are trusted, version-controlled shell assignments under build/profiles/.

load_gamma_profile() {
    local edition="${1:-}"
    local root="${2:-}"
    local profile="$root/build/profiles/$edition.conf"

    if [[ -z "$edition" || -z "$root" || ! -f "$profile" ]]; then
        echo "ERROR: No build profile found for edition '$edition'." >&2
        echo "Expected: $profile" >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "$profile"

    : "${EDITION:?Profile must define EDITION}"
    : "${BASE_DISTRO:?Profile must define BASE_DISTRO}"
    : "${BASE_SUITE:?Profile must define BASE_SUITE}"
    : "${BASE_ARCH:?Profile must define BASE_ARCH}"
    : "${BASE_MIRROR:?Profile must define BASE_MIRROR}"
    : "${SECURITY_MIRROR:?Profile must define SECURITY_MIRROR}"
    : "${APT_COMPONENTS:?Profile must define APT_COMPONENTS}"
    : "${KERNEL_PACKAGE:?Profile must define KERNEL_PACKAGE}"
    : "${LIVE_DIR:?Profile must define LIVE_DIR}"
    : "${LIVE_BOOT_PARAM:?Profile must define LIVE_BOOT_PARAM}"
    : "${LIVE_USERNAME:?Profile must define LIVE_USERNAME}"
    : "${LIVE_USER_FULLNAME:?Profile must define LIVE_USER_FULLNAME}"
    : "${HOSTNAME:?Profile must define HOSTNAME}"
    : "${SWAPPINESS:?Profile must define SWAPPINESS}"
    : "${VFS_CACHE:?Profile must define VFS_CACHE}"
    : "${DIRTY_RATIO:?Profile must define DIRTY_RATIO}"
    : "${ZRAM_PERCENT:?Profile must define ZRAM_PERCENT}"
    : "${EXTRA_PACKAGES?Profile must define EXTRA_PACKAGES}"

    if [[ "$EDITION" != "$edition" || "$BASE_DISTRO" != "debian" ]]; then
        echo "ERROR: Invalid or mismatched Gamma build profile: $profile" >&2
        return 1
    fi

    # Keep the supported target matrix explicit. A profile cannot silently
    # switch an edition to an unreviewed distribution or architecture.
    case "$EDITION:$BASE_SUITE:$BASE_ARCH:$KERNEL_PACKAGE" in
        pro:trixie:amd64:linux-image-amd64|lite:trixie:amd64:linux-image-amd64|legacy:bookworm:i386:linux-image-686-pae)
            ;;
        *)
            echo "ERROR: Unsupported target tuple in $profile:" >&2
            echo "       $EDITION / $BASE_SUITE / $BASE_ARCH / $KERNEL_PACKAGE" >&2
            return 1
            ;;
    esac

    for setting in "$SWAPPINESS" "$VFS_CACHE" "$DIRTY_RATIO" "$ZRAM_PERCENT"; do
        if [[ ! "$setting" =~ ^[0-9]+$ ]]; then
            echo "ERROR: Memory tuning values must be non-negative integers in $profile." >&2
            return 1
        fi
    done

    if [[ ! "$LIVE_USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "ERROR: Invalid Debian Live username in $profile." >&2
        return 1
    fi

    if [[ "$LIVE_DIR" != "live" || "$LIVE_BOOT_PARAM" != "boot=live" ]]; then
        echo "ERROR: All Debian Gamma editions must use /live and boot=live." >&2
        return 1
    fi

    echo "[profile] $EDITION: Debian $BASE_SUITE ($BASE_ARCH)"
}
