#!/bin/bash
# Mirrors Firmware/system/config.sh but builds out-of-tree into the
# persistent /build volume so the heavy I/O never touches the macOS
# bind mount. The downloaded Buildroot tree, dl/ cache and ccache all
# live under /build and survive between runs.
#
# Stage argument:
#   config      download + extract + reset .config from gate_zero_defconfig
#   menuconfig  edit .config and export a candidate defconfig
#   all/(none)  full build from the repository defconfig
set -euo pipefail

# Buildroot release is passed in by docker-build.sh (read from config.sh) so
# it always matches the branch; the fallback is just a safety net.
BR_RELEASE="${BR_RELEASE:-buildroot-2026.02.1}"
STAGE="${1:-all}"

# Buildroot stamps are not safe to reuse across releases. In particular, a
# host package can keep the same version while the host Python ABI changes,
# leaving a valid-looking stamp for a module installed under the old Python.
# Keep build/host/staging/target release-specific while sharing downloads and
# ccache across releases.
OUTPUT_DIR="/build/output-${BR_RELEASE#buildroot-}"

export HOME=/build          # ccache and other host state persist in the volume

# Shared download cache, decoupled from the buildroot tree, so a release bump
# (2024.02 -> 2026.02.x) reuses already-downloaded tarballs instead of
# re-fetching. Lives in the volume, so it survives across runs.
export BR2_DL_DIR=/build/dl
mkdir -p "${BR2_DL_DIR}"

cd /build

if [ ! -e "${BR_RELEASE}.tar.gz" ]; then
    echo ">> Downloading ${BR_RELEASE}"
    wget -q "https://buildroot.org/downloads/${BR_RELEASE}.tar.gz"
fi

if [ ! -d "${BR_RELEASE}" ]; then
    echo ">> Extracting ${BR_RELEASE}"
    tar xf "${BR_RELEASE}.tar.gz"
fi

CONFIG="${OUTPUT_DIR}/.config"

apply_defconfig() {
    echo ">> Applying gate_zero_defconfig"
    make -C "${BR_RELEASE}" BR2_EXTERNAL=/build/br2_external O="${OUTPUT_DIR}" gate_zero_defconfig
}

case "${STAGE}" in
    config)
        # Reset .config from the repo defconfig.
        apply_defconfig
        echo ">> Config reset from defconfig"
        exit 0
        ;;
    menuconfig)
        # Interactively edit the release-specific .config and export a minimal
        # defconfig that can be reviewed and committed back to the repo.
        [ -e "${CONFIG}" ] || apply_defconfig
        make -C "${OUTPUT_DIR}" menuconfig
        make -C "${OUTPUT_DIR}" savedefconfig BR2_DEFCONFIG="${OUTPUT_DIR}/defconfig"
        cp -v "${OUTPUT_DIR}/defconfig" /build/out/gate_zero_defconfig
        echo ">> Edited .config kept for future menuconfig sessions."
        echo ">> Minimal defconfig exported to out/gate_zero_defconfig — review it,"
        echo ">> then replace br2_external/configs/gate_zero_defconfig to persist."
        exit 0
        ;;
    all)
        # Always regenerate .config from the repo defconfig so the build is
        # reproducible and never runs on a stale .config left in the volume.
        # To bake in menuconfig changes, replace the repo defconfig with the
        # one exported by the `menuconfig` stage, then build.
        apply_defconfig
        ;;
    *)
        echo "Usage: build.sh [all|config|menuconfig]" >&2
        exit 2
        ;;
esac

echo ">> Building (first run compiles a full cross toolchain, expect a long wait)"
make -C "${OUTPUT_DIR}"

echo ">> Copying image"
IMAGE_SOURCE="${OUTPUT_DIR}/images/sdcard.img"
IMAGE_DEST="/build/out/sdcard.img"
IMAGE_TMP="${IMAGE_DEST}.tmp"

# The macOS/OrbStack bind mount cannot punch holes in sparse files. Force a
# dense sequential copy to a temporary file, then atomically rename it so a
# failed export never truncates the last usable image.
cleanup_image_export() {
    rm -f -- "${IMAGE_TMP}"
}
trap cleanup_image_export EXIT
cleanup_image_export
cp --sparse=never -v "${IMAGE_SOURCE}" "${IMAGE_TMP}"
mv -f -- "${IMAGE_TMP}" "${IMAGE_DEST}"
trap - EXIT

echo ">> Done: out/sdcard.img"
