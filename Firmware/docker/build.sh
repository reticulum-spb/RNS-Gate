#!/bin/bash
# Mirrors Firmware/system/config.sh but builds out-of-tree into the
# persistent /build volume so the heavy I/O never touches the macOS
# bind mount. The downloaded Buildroot tree, dl/ cache and ccache all
# live under /build and survive between runs.
#
# Stage argument:
#   config   download + extract + run gate_zero_defconfig, then stop
#   (none)   full build, then copy images/sdcard.img to /build/out
set -euo pipefail

BR_RELEASE="buildroot-2024.02"
STAGE="${1:-all}"

export HOME=/build          # ccache and other host state persist in the volume
cd /build

if [ ! -e "${BR_RELEASE}.tar.gz" ]; then
    echo ">> Downloading ${BR_RELEASE}"
    wget -q "https://buildroot.org/downloads/${BR_RELEASE}.tar.gz"
fi

if [ ! -d "${BR_RELEASE}" ]; then
    echo ">> Extracting ${BR_RELEASE}"
    tar xf "${BR_RELEASE}.tar.gz"
fi

echo ">> Configuring (gate_zero_defconfig)"
make -C "${BR_RELEASE}" BR2_EXTERNAL=/build/br2_external O=/build/output gate_zero_defconfig

if [ "${STAGE}" = "config" ]; then
    echo ">> Config-only stage complete"
    exit 0
fi

echo ">> Building (first run compiles a full cross toolchain, expect a long wait)"
make -C /build/output

echo ">> Copying image"
cp -v /build/output/images/sdcard.img /build/out/sdcard.img

echo ">> Done: out/sdcard.img"
