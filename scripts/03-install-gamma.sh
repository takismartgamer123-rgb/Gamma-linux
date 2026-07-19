#!/bin/bash
set -e
echo "[03] Building Gamma CC + Theme"

# Build Gamma CC
cd src/gamma-cc && mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr.. && make -j$(nproc)
sudo make install DESTDIR=$GITHUB_WORKSPACE/chroot
cd $GITHUB_WORKSPACE

# Build Theme
edje_cc src/gamma-ios-theme/gamma-ios.edc src/gamma-ios-theme/gamma-ios.edj
sudo mkdir -p chroot/usr/share/enlightenment/data/themes/gamma-ios/
sudo cp src/gamma-ios-theme/gamma-ios.edj chroot/usr/share/enlightenment/data/themes/gamma-ios/
sudo cp src/gamma-ios-theme/theme.desktop chroot/usr/share/enlightenment/data/themes/gamma-ios/
