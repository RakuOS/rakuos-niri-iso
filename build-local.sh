#!/usr/bin/env bash
# Build the RakuOS Niri ISO locally using rakuos-forge's Justfile.
#
# Usage: ./build-local.sh [branch_slug]
#   branch_slug defaults to "latest" (i.e. quay.io/rakuos/rakuos-niri:latest)
#
# Requires `just` and a checkout of rakuos-forge (default: found as a sibling
# monorepo path ../../packages/rakuos/rakuos-forge; override with FORGE_DIR).

set -euo pipefail

if ! command -v just >/dev/null 2>&1; then
  echo "ERROR: just is not installed (dnf install just)" >&2
  exit 1
fi

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_DIR="${FORGE_DIR:-${SELF_DIR}/../../packages/rakuos/rakuos-forge}"
if [ ! -f "${FORGE_DIR}/Justfile" ]; then
  echo "ERROR: no Justfile found at ${FORGE_DIR} (set FORGE_DIR to a rakuos-forge checkout)" >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Re-executing with sudo (build needs real root for privileged container setup)..."
  exec sudo --preserve-env=COMPRESSION,BUILDER_DISTRO,FORGE_DIR "$0" "$@"
fi

IMAGE_REPO="quay.io/rakuos/rakuos-niri"
BRANCH_SLUG="${1:-latest}"
IMAGE_REF="${IMAGE_REPO}:${BRANCH_SLUG}"
COMPRESSION="${COMPRESSION:-squashfs}"

export TITANOBOA_BUILDER_DISTRO="${BUILDER_DISTRO:-fedora}"
export HOOK_post_rootfs="${SELF_DIR}/config/configure-iso.sh"
export HOOK_pre_initramfs="${SELF_DIR}/config/pre_initramfs.sh"

# Clean up leftovers from previous runs (stale output.iso from an
# interrupted build, old ISOs in output/) so a failed/older run can
# never be mistaken for the result of this one.
rm -f "${SELF_DIR}/output.iso"
rm -rf "${SELF_DIR}/output"

(cd "${SELF_DIR}" && just -f "${FORGE_DIR}/Justfile" build "${IMAGE_REF}" 1 none "${COMPRESSION}" NONE "${IMAGE_REF}" 1)

mkdir -p "${SELF_DIR}/output"
mv "${SELF_DIR}/output.iso" "${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso"
echo "Built: ${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso"
