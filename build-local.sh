#!/usr/bin/env bash
# Build a RakuOS Niri ISO locally, mirroring the .gitlab-ci.yml build-iso-standard
# job minus the upload steps. Produces output/rakuos-niri-<tag>-<date>-amd64.iso.
#
# Requires root/sudo, podman, and the same package set the CI runner installs
# (see rakuos-forge README's Prerequisites section). On Fedora:
#   sudo dnf install -y podman jq curl findutils tar xorriso dosfstools \
#     grub2 grub2-efi grub2-tools grub2-tools-extra grub2-efi-x64 \
#     grub2-efi-x64-cdboot grub2-efi-x64-modules shim squashfs-tools erofs-utils
#
# Usage:
#   sudo ./build-local.sh [image-tag]
# image-tag defaults to "latest" (quay.io/rakuos/rakuos-niri:<image-tag>).

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script needs root (loop devices, mounts, chroot). Re-run with sudo." >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

IMAGE_REPO="quay.io/rakuos/rakuos-niri"
PLATFORM="amd64"
COMPRESSION="${COMPRESSION:-squashfs}"
IMAGE_TAG="${1:-latest}"
IMAGE_REF="${IMAGE_REPO}:${IMAGE_TAG}"
BUILD_DATE="$(date -u +%Y.%m.%d)"

echo "Building ${IMAGE_REF} (compression: ${COMPRESSION})"

if ! command -v rakuos-forge >/dev/null 2>&1; then
  echo "rakuos-forge not found on PATH, building it from source into ./rakuos-forge"
  if [[ ! -d "${SCRIPT_DIR}/rakuos-forge" ]]; then
    git clone --depth 1 https://gitlab.com/rakuos/packages/rakuos/rakuos-forge.git "${SCRIPT_DIR}/rakuos-forge"
  fi
  (cd "${SCRIPT_DIR}/rakuos-forge" && cargo build --release --locked)
  RAKUOS_FORGE_BIN="${SCRIPT_DIR}/rakuos-forge/target/release/rakuos-forge"
else
  RAKUOS_FORGE_BIN="$(command -v rakuos-forge)"
fi

export RAKUFORGE_BUILDER_DISTRO="${RAKUFORGE_BUILDER_DISTRO:-fedora}"
export HOOK_post_rootfs="${SCRIPT_DIR}/config/configure-iso.sh"
export HOOK_pre_initramfs="${SCRIPT_DIR}/config/pre_initramfs.sh"

"${RAKUOS_FORGE_BIN}" build "${IMAGE_REF}" \
  --flatpaks-file none \
  --compression "${COMPRESSION}" \
  --extra-kargs NONE \
  --container-image "${IMAGE_REF}"

if [[ ! -f output.iso ]]; then
  echo "ERROR: output.iso not found after build" >&2
  exit 1
fi

mkdir -p output
ISO_NAME="rakuos-niri-${IMAGE_TAG}-${BUILD_DATE}-${PLATFORM}.iso"
mv output.iso "output/${ISO_NAME}"
sha256sum "output/${ISO_NAME}" > "output/${ISO_NAME}.sha256"

echo "Built output/${ISO_NAME}"
echo "Test it with: rakuos-forge vm output/${ISO_NAME}"
