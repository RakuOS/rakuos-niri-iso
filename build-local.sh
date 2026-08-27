#!/usr/bin/env bash
# Build the RakuOS Niri ISO locally using the rakuos-forge binary.
#
# Usage: ./build-local.sh [branch_slug]
#   branch_slug defaults to "latest" (i.e. quay.io/rakuos/rakuos-niri:latest)
#
# Requires `rakuos-forge` to be installed (dnf install rakuos-forge, after
# adding https://repo.rakuos.org/rakuos.repo).

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Re-executing with sudo (build needs real root for privileged container setup)..."
  exec sudo --preserve-env=COMPRESSION,BUILDER_DISTRO "$0" "$@"
fi

if ! command -v rakuos-forge >/dev/null 2>&1; then
  echo "ERROR: rakuos-forge is not installed (dnf install rakuos-forge, after adding https://repo.rakuos.org/rakuos.repo)" >&2
  exit 1
fi

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean up leftovers from previous runs (stale output.iso/output/, work/) so a
# failed/older run can never be mistaken for the result of this one.
rm -f "${SELF_DIR}/output.iso"
rm -rf "${SELF_DIR}/output"
rm -rf "${SELF_DIR}/work"

IMAGE_REPO="quay.io/rakuos/rakuos-niri"
BRANCH_SLUG="${1:-latest}"
IMAGE_REF="${IMAGE_REPO}:${BRANCH_SLUG}"
COMPRESSION="${COMPRESSION:-squashfs}"

export RAKUFORGE_BUILDER_DISTRO="${BUILDER_DISTRO:-fedora}"
export HOOK_post_rootfs="${SELF_DIR}/config/configure-iso.sh"
export HOOK_pre_initramfs="${SELF_DIR}/config/pre_initramfs.sh"

cd "${SELF_DIR}"
rakuos-forge build "${IMAGE_REF}" --compression "${COMPRESSION}" --container-image "${IMAGE_REF}"

mkdir -p "${SELF_DIR}/output"
mv "${SELF_DIR}/output.iso" "${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso"

( cd "${SELF_DIR}/output" && sha256sum "rakuos-niri-${BRANCH_SLUG}.iso" > "rakuos-niri-${BRANCH_SLUG}.iso.sha256" )

echo "Built: ${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso"
echo "SHA256: ${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso.sha256"
