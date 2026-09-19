#!/bin/sh
set -eu

BOARD_DIR="${BR2_EXTERNAL_GATE_PATH}/board/gate"

# Factory images start with an invalid environment; U-Boot initializes slot A.
dd if=/dev/zero of="${BINARIES_DIR}/uboot-env.bin" bs=65536 count=2

support/scripts/genimage.sh -c "${BOARD_DIR}/genimage.cfg"

# Keep the RAUC bundle manifest beside the factory artifacts. A release
# pipeline packages it with rootfs.ext4 and signs the resulting .raucb bundle.
install -m 0644 "${BOARD_DIR}/manifest.raucm" "${BINARIES_DIR}/manifest.raucm"
