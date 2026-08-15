#!/usr/bin/env bash
# Host-side wrapper that builds the Buildroot container and runs the
# RNS-Gate image build inside it.
#
#   ./docker-build.sh            full build -> Firmware/docker/output/sdcard.img
#   ./docker-build.sh config     reset .config from the defconfig (fast)
#   ./docker-build.sh menuconfig edit and export a candidate defconfig
#
# The Buildroot work tree lives in the named volume $VOLUME, not on the
# macOS filesystem, so rebuilds reuse the toolchain and download cache.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="rns-gate-builder"
VOLUME="rns-gate-build"
OUT_DIR="${SCRIPT_DIR}/docker/output"
STAGE="${1:-all}"

case "${STAGE}" in
    all|config|menuconfig) ;;
    *)
        echo "Usage: $0 [all|config|menuconfig]" >&2
        exit 2
        ;;
esac

# Single source of truth for the Buildroot version: config.sh. Keeps the
# container in step with the branch (2024.02 on master, 2026.02.x on the
# Rust branch) instead of hardcoding a release in build.sh.
BR_RELEASE="$(grep -oE 'buildroot-[0-9.]+' "${SCRIPT_DIR}/system/config.sh" | head -1)"

mkdir -p "${OUT_DIR}"

echo ">> Building Docker image ${IMAGE}"
docker build -t "${IMAGE}" "${SCRIPT_DIR}/docker"

COMMON_ARGS=(
    -e "BR_RELEASE=${BR_RELEASE}"
    -v "${VOLUME}:/build"
    -v "${SCRIPT_DIR}/system/br2_external:/build/br2_external:ro"
    -v "${OUT_DIR}:/build/out"
)

if [ "${STAGE}" = "menuconfig" ]; then
    # Interactive: needs a TTY, and tee would break ncurses.
    docker run --rm -it "${COMMON_ARGS[@]}" "${IMAGE}" "$@"
else
    echo ">> Building Buildroot ${BR_RELEASE} (full log: ${OUT_DIR}/build.log)"
    echo ">> Watch package-by-package progress with:"
    echo ">>     tail -f ${OUT_DIR}/build.log | grep --line-buffered '^>>>'"
    if ! docker run --rm "${COMMON_ARGS[@]}" "${IMAGE}" "$@" 2>&1 | tee "${OUT_DIR}/build.log"; then
        if [ "${STAGE}" = "all" ] && [ -e "${OUT_DIR}/sdcard.img" ]; then
            echo ">> Build failed; any existing sdcard.img was not produced by this run." >&2
        fi
        exit 1
    fi
fi

echo ">> Output directory: ${OUT_DIR}"
