#!/usr/bin/env bash
# Build the RakuOS Niri ISO locally using rakuos-forge's Justfile.
#
# Usage: ./build-local.sh [branch_slug]
#   branch_slug defaults to "latest" (i.e. quay.io/rakuos/rakuos-niri:latest)
#
# Requires `just`. Clones rakuos-forge fresh (TITANOBOA_REPO/TITANOBOA_REF,
# same as CI) into ./rakuos-forge unless it's already there.

set -euo pipefail

if ! command -v just >/dev/null 2>&1; then
  echo "ERROR: just is not installed (dnf install just)" >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Re-executing with sudo (build needs real root for privileged container setup)..."
  exec sudo --preserve-env=COMPRESSION,BUILDER_DISTRO,TITANOBOA_REPO,TITANOBOA_REF "$0" "$@"
fi

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TITANOBOA_REPO="${TITANOBOA_REPO:-https://gitlab.com/rakuos/packages/rakuos/rakuos-forge.git}"
TITANOBOA_REF="${TITANOBOA_REF:-main}"
FORGE_DIR="${SELF_DIR}/rakuos-forge"

rm -rf "${FORGE_DIR}"
git clone --depth 1 --branch "${TITANOBOA_REF}" "${TITANOBOA_REPO}" "${FORGE_DIR}"

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
