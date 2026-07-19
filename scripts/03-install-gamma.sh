#!/usr/bin/env bash
set -euo pipefail

echo "[03] Building Gamma CC + Theme"

ROOT="$PWD"

# ==========================
# Build Gamma CC
# ==========================

cd src/gamma-cc

mkdir -p build
cd build

cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make -j"$(nproc)"

sudo make install DESTDIR="$ROOT/chroot"

cd "$ROOT"

# ==========================
# Build Gamma Theme
# ==========================

edje_cc \
    src/gamma-ios-theme/gamma-ios.edc \
    src/gamma-ios-theme/gamma-ios.edj

sudo mkdir -p \
chroot/usr/share/enlightenment/data/themes/gamma-ios

sudo cp \
src/gamma-ios-theme/gamma-ios.edj \
chroot/usr/share/enlightenment/data/themes/gamma-ios/

sudo cp \
src/gamma-ios-theme/theme.desktop \
chroot/usr/share/enlightenment/data/themes/gamma-ios/

echo "[03] Gamma components installed."
