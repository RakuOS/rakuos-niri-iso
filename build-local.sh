#!/usr/bin/env bash
# Build the RakuOS Niri ISO locally using rakuos-forge (Rust CLI).
#
# Usage: sudo ./build-local.sh [branch_slug]
#   branch_slug defaults to "latest" (i.e. quay.io/rakuos/rakuos-niri:latest)
#
# Set FORGE_DIR to point at a local rakuos-forge checkout to skip cloning
# (useful when iterating on rakuos-forge itself, e.g. FORGE_DIR=../../packages/rakuos/rakuos-forge).

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: must be run as root" >&2
  exit 1
fi

IMAGE_REPO="quay.io/rakuos/rakuos-niri"
BRANCH_SLUG="${1:-latest}"
IMAGE_REF="${IMAGE_REPO}:${BRANCH_SLUG}"
COMPRESSION="${COMPRESSION:-squashfs}"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FORGE_DIR="${FORGE_DIR:-}"
if [ -z "${FORGE_DIR}" ]; then
  FORGE_DIR="${SELF_DIR}/rakuos-forge"
  if [ ! -d "${FORGE_DIR}" ]; then
    git clone --depth 1 https://gitlab.com/rakuos/packages/rakuos/rakuos-forge.git "${FORGE_DIR}"
  fi
fi

(cd "${FORGE_DIR}" && cargo build --release)
FORGE_BIN="${FORGE_DIR}/target/release/rakuos-forge"

export TITANOBOA_BUILDER_DISTRO="${BUILDER_DISTRO:-fedora}"
export HOOK_post_rootfs="${SELF_DIR}/config/configure-iso.sh"
export HOOK_pre_initramfs="${SELF_DIR}/config/pre_initramfs.sh"

(cd "${FORGE_DIR}" && "${FORGE_BIN}" build "${IMAGE_REF}" --flatpaks-file none --compression "${COMPRESSION}" --extra-kargs NONE --container-image "${IMAGE_REF}")

mkdir -p "${SELF_DIR}/output"
mv "${FORGE_DIR}/output.iso" "${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso"
echo "Built: ${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso"
