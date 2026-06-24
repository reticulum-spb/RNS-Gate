#!/usr/bin/env bash
# Host-side wrapper that builds the Buildroot container and runs the
# RNS-Gate image build inside it.
#
#   ./docker-build.sh            full build -> Firmware/docker/output/sdcard.img
#   ./docker-build.sh config     validate the defconfig only (fast)
#
# The Buildroot work tree lives in the named volume $VOLUME, not on the
# macOS filesystem, so rebuilds reuse the toolchain and download cache.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="rns-gate-builder"
VOLUME="rns-gate-build"
OUT_DIR="${SCRIPT_DIR}/docker/output"

mkdir -p "${OUT_DIR}"

echo ">> Building Docker image ${IMAGE}"
docker build -t "${IMAGE}" "${SCRIPT_DIR}/docker"

echo ">> Running Buildroot build (full log: ${OUT_DIR}/build.log)"
echo ">> Watch package-by-package progress with:"
echo ">>     tail -f ${OUT_DIR}/build.log | grep --line-buffered '^>>>'"
docker run --rm \
    -v "${VOLUME}:/build" \
    -v "${SCRIPT_DIR}/system/br2_external:/build/br2_external:ro" \
    -v "${OUT_DIR}:/build/out" \
    "${IMAGE}" "$@" 2>&1 | tee "${OUT_DIR}/build.log"

echo ">> Output directory: ${OUT_DIR}"
