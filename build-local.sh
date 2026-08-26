#!/usr/bin/env bash
# Build the RakuOS Niri ISO locally using the installed rakuos-forge (Rust CLI).
#
# Usage: ./build-local.sh [branch_slug]
#   branch_slug defaults to "latest" (i.e. quay.io/rakuos/rakuos-niri:latest)
#
# Requires the rakuos-forge package to already be installed on the system.

set -euo pipefail

if ! command -v rakuos-forge >/dev/null 2>&1; then
  echo "ERROR: rakuos-forge is not installed (dnf install rakuos-forge)" >&2
  exit 1
fi

# The build needs real root (loop-device setup for efiboot.img, privileged
# podman --rootfs/--privileged runs) — rootless podman can't get the kernel
# to allocate new /dev/loopN devices no matter what flags it's given. Re-exec
# under sudo up front rather than relying on rakuos-forge to sudo internally.
if [ "$(id -u)" -ne 0 ]; then
  echo "Re-executing with sudo (build needs real root for loop-device/privileged container setup)..."
  exec sudo --preserve-env=COMPRESSION,BUILDER_DISTRO "$0" "$@"
fi

IMAGE_REPO="quay.io/rakuos/rakuos-niri"
BRANCH_SLUG="${1:-latest}"
IMAGE_REF="${IMAGE_REPO}:${BRANCH_SLUG}"
COMPRESSION="${COMPRESSION:-squashfs}"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export RAKUFORGE_BUILDER_DISTRO="${BUILDER_DISTRO:-fedora}"
export HOOK_post_rootfs="${SELF_DIR}/config/configure-iso.sh"
export HOOK_pre_initramfs="${SELF_DIR}/config/pre_initramfs.sh"

(cd "${SELF_DIR}" && rakuos-forge build "${IMAGE_REF}" --flatpaks-file none --compression "${COMPRESSION}" --extra-kargs NONE --container-image "${IMAGE_REF}")

mkdir -p "${SELF_DIR}/output"
mv "${SELF_DIR}/output.iso" "${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso"
echo "Built: ${SELF_DIR}/output/rakuos-niri-${BRANCH_SLUG}.iso"
