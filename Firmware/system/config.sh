#!/usr/bin/env bash
set -euo pipefail

BR_RELEASE="buildroot-2026.02.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output_gate-${BR_RELEASE#buildroot-}"

cd "${SCRIPT_DIR}"

if [ ! -e "${BR_RELEASE}.tar.gz" ]; then
  wget "https://buildroot.org/downloads/${BR_RELEASE}.tar.gz"
fi

if [ ! -d "${BR_RELEASE}" ]; then
  tar xf "${BR_RELEASE}.tar.gz"
fi

make -C "${BR_RELEASE}" \
  BR2_EXTERNAL="${SCRIPT_DIR}/br2_external" \
  O="${OUTPUT_DIR}" \
  gate_zero_defconfig

echo "Build with: make -C ${OUTPUT_DIR}"
