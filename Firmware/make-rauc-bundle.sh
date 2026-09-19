#!/bin/bash
# Assemble a *signed plain* RAUC update bundle from the last local buildroot build.
#
#   ./make-rauc-bundle.sh                       dev bundle signed with Firmware/rauc-keys
#   ./make-rauc-bundle.sh /path/to/rootfs.ext4  same, with explicit rootfs image
#
# Only needs squashfs-tools, openssl and python3 on the host. The output follows
# the exact bundle layout RAUC >= 1.5 expects for 'plain' format
# (rauc src/bundle.c: append_signature_to_bundle):
#
#   [ gzip squashfs of staging dir ][ detached CMS over the squashfs ][ uint64 BE sigsize ]
#
# The trailing 8-byte big-endian signature size is what open_local_bundle()
# reads first - without it RAUC fails with "Signature size is 0".
# The CA matching the signing key must be present in the target's
# /etc/rauc/ca.cert.pem (post-build.sh installs it from board/gate).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOARD_DIR="${SCRIPT_DIR}/system/br2_external/board/gate"
KEYS_DIR="${SCRIPT_DIR}/rauc-keys"
OUT_DIR="${SCRIPT_DIR}/docker/output"

CERT="${KEYS_DIR}/cert.pem"
KEY="${KEYS_DIR}/key.pem"

# Dev signing keypair: generated automatically on first use, gitignored.
if [ ! -f "${CERT}" ] || [ ! -f "${KEY}" ]; then
    echo ">> Generating dev signing keypair in ${KEYS_DIR} (one-time)"
    mkdir -p "${KEYS_DIR}"
    openssl req -x509 -newkey rsa:4096 -nodes -days 3650 \
        -subj "/CN=RNS Gate Dev CA" \
        -addext "basicConstraints=critical,CA:TRUE" \
        -keyout "${KEY}" -out "${CERT}"
fi

if [ "${1:-}" = "--sign" ]; then
    echo "note: signing is always on now; ignoring --sign" >&2
    shift
fi

ROOTFS="${1:-${OUT_DIR}/rootfs.ext4}"
[ -f "${ROOTFS}" ] || { echo "rootfs not found: ${ROOTFS}" >&2; exit 1; }

# Bundle version comes from the manifest template (version=... in [update]).
VERSION="$(sed -n 's/^version=//p' "${BOARD_DIR}/manifest.raucm")"

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT

cp "${BOARD_DIR}/manifest.raucm" "${STAGE}/manifest.raucm"
# Plain bundles carry an internal manifest; RAUC requires the image checksum
# and size to be recorded in it (check_manifest_internal).
sed -i 's/^format=.*/format=plain/' "${STAGE}/manifest.raucm"
SHA256="$(sha256sum "${ROOTFS}" | cut -d' ' -f1)"
SIZE="$(stat -c%s "${ROOTFS}")"
sed -i "/^filename=rootfs.ext4/a sha256=${SHA256}\nsize=${SIZE}" "${STAGE}/manifest.raucm"
cp "${ROOTFS}" "${STAGE}/rootfs.ext4"

OUT="${OUT_DIR}/update-${VERSION}.raucb"
rm -f "${OUT}" "${OUT}.squashfs" "${OUT}.sig"

# 1. Compressed squashfs payload (~90M instead of 513M uncompressed cpio).
mksquashfs "${STAGE}" "${OUT}.squashfs" -quiet -noappend -comp gzip -all-root

# 2. Detached CMS signature over the squashfs (plain format = signed payload).
openssl cms -sign -binary -outform DER -md sha256 \
    -signer "${CERT}" -inkey "${KEY}" \
    -in "${OUT}.squashfs" -out "${OUT}.sig"

# 3. payload + signature + 8-byte big-endian signature size.
cat "${OUT}.squashfs" "${OUT}.sig" > "${OUT}"
python3 - "${OUT}" "$(stat -c%s "${OUT}.sig")" <<'EOF'
import struct, sys
with open(sys.argv[1], "ab") as f:
    f.write(struct.pack(">Q", int(sys.argv[2])))
EOF
rm -f "${OUT}.squashfs" "${OUT}.sig"

ls -la "${OUT}"
echo ">> Bundle ready (signed plain, dev CA): ${OUT}"
echo ">> Deploy:       scp ${OUT} root@<gate>:/mnt/rns/ && rauc install /mnt/rns/$(basename "${OUT}")"