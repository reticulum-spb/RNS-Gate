#!/bin/sh

# genimage will need to find the extlinux.conf
# in the binaries directory

BOARD_DIR="${BR2_EXTERNAL_GATE_PATH}/board/gate"

install -m 0644 -D "${BOARD_DIR}/extlinux.conf" "${TARGET_DIR}/boot/extlinux/extlinux.conf"
install -m 0644 -D "${BOARD_DIR}/genimage.cfg" "$BINARIES_DIR/genimage.cfg"

# RAUC: system configuration, bootloader environment access and the
# keyring used to verify update bundles. The development CA ships so that
# locally built bundles verify out of the factory image; swap in the
# production CA for release signing.
install -m 0644 -D "${BOARD_DIR}/rauc-system.conf" "${TARGET_DIR}/etc/rauc/system.conf"
install -m 0644 -D "${BOARD_DIR}/fw_env.config" "${TARGET_DIR}/etc/fw_env.config"
install -m 0644 -D "${BOARD_DIR}/rauc-ca.cert.pem" "${TARGET_DIR}/etc/rauc/ca.cert.pem"

rm -rf "${BINARIES_DIR}/rns"
cp -r "${TARGET_DIR}/mnt/rns/" "${BINARIES_DIR}/rns"

# WiFi fix

if [ -f "${TARGET_DIR}/etc/init.d/S10udev" ]; then
    mv "${TARGET_DIR}/etc/init.d/S10udev" "${TARGET_DIR}/etc/init.d/S46udev"
fi
