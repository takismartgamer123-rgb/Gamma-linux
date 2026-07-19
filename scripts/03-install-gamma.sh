#!/usr/bin/env bash
set -euo pipefail

echo "[03] Building Gamma Components"

ROOT="$(pwd)"

# ==========================================
# Check Sources
# ==========================================

[ -d src/gamma-cc ] || { echo "ERROR: src/gamma-cc not found."; exit 1; }

[ -f src/gamma-ios-theme/gamma-ios.edc ] || {
    echo "ERROR: gamma-ios.edc not found."
    exit 1
}

# ==========================================
# Build Gamma CC
# ==========================================

echo "[03] Building Gamma CC..."

mkdir -p src/gamma-cc/build

cd src/gamma-cc/build

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    ..

make -j"$(nproc)"

sudo make install DESTDIR="$ROOT/chroot"

cd "$ROOT"

# ==========================================
# Build Theme
# ==========================================

echo "[03] Building Gamma Theme..."

edje_cc \
    src/gamma-ios-theme/gamma-ios.edc \
    src/gamma-ios-theme/gamma-ios.edj

sudo install -d \
    chroot/usr/share/enlightenment/data/themes/gamma-ios

sudo install -m644 \
    src/gamma-ios-theme/gamma-ios.edj \
    chroot/usr/share/enlightenment/data/themes/gamma-ios/

sudo install -m644 \
    src/gamma-ios-theme/theme.desktop \
    chroot/usr/share/enlightenment/data/themes/gamma-ios/

echo "[03] Gamma Components installed successfully."
