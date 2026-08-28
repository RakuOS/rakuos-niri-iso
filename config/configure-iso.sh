#!/usr/bin/env bash

set -exo pipefail

source /etc/os-release

# sudo requires drop-in files to be owned by root and not be writable by others
chown root:root /etc/sudoers.d
chmod 0750 /etc/sudoers.d
chown root:root /etc/sudoers.d/rakuos
chmod 0440 /etc/sudoers.d/rakuos
chown root:root /etc/sudoers.d/pwfeedback
chmod 0440 /etc/sudoers.d/pwfeedback
chown root:root /etc/sudoers.d/secure-path
chmod 0440 /etc/sudoers.d/secure-path

# Remove all versionlocks to avoid dependency issues
rum -qy versionlock clear

# Install RakuOS installer (GTK frontend + common backend + fisherman)
rum install -qy rakuos-installer-gtk

# Allow the RakuOS installer's local `oci:` re-export of this image to pass
# signature policy: the default policy.json (default: reject, per-registry
# allowances only under the `docker` transport) has no `oci` transport entry,
# so bootc install --source-imgref oci:... gets rejected with "Source image
# ... is rejected by policy." even though the OCI export never leaves this
# same, already-trusted image. Scope the relaxation to `oci` only -- leave
# the registry/sigstore checks under `docker` untouched.
python3 - <<'PY'
import json
path = "/etc/containers/policy.json"
with open(path) as f:
    policy = json.load(f)
policy.setdefault("transports", {})["oci"] = {"": [{"type": "insecureAcceptAnything"}]}
with open(path, "w") as f:
    json.dump(policy, f, indent=2)
PY

# Mask overlay services so they cannot be started or pulled in on the live ISO
systemctl mask rakuos-overlay-sync.service rakuos-overlay-mount.service

# Read packages into array and install
mapfile -t PACKAGES < <(
    grep -v '^\s*#' "/usr/share/rakuos/packages-live.list" \
    | grep -v '^\s*$' \
    | sed 's/\s*#.*//' \
    | tr -s ' \t' '\n' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | grep -v '^$'
) || true

rum install -y --refresh "${PACKAGES[@]}"

# Reset RakuOS overlay state for live ISO
echo "Resetting RakuOS overlay state for live ISO..."
rm -rf /var/lib/rakuos
mkdir -p /var/lib/rakuos
if [[ -f /usr/share/rakuos/packages-live.list ]]; then
    cp /usr/share/rakuos/packages-live.list /var/lib/rakuos/packages.list
    sed -i -e '$a\' /var/lib/rakuos/packages.list
fi

# Variables
imageref="$(podman images --format '{{ index .Names 0 }}\n' 'rakuos*' | head -1)"
imageref="${imageref##*://}"
imageref="${imageref%%:*}"
imagetag="$(podman images --format '{{ .Tag }}\n' "$imageref" | head -1)"

echo "RakuOS release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

# Get shared artwork and system files from iso-base
git clone --depth 1 --quiet https://gitlab.com/rakuos/iso/iso-base.git /root/packages

### Desktop-environment specific tweaks ###

# Use GSK_RENDERER=gl for NVIDIA — workaround for GTK apps not opening
if [[ $imageref == *-nvidia* ]]; then
    mkdir -p /etc/environment.d /etc/skel/.config/environment.d
    echo "GSK_RENDERER=gl" >>/etc/environment.d/99-nvidia-fix.conf
    echo "GSK_RENDERER=gl" >>/etc/skel/.config/environment.d/99-nvidia-fix.conf
fi

# Re-enable nouveau for the live session on NVIDIA images
if [[ $imageref == *-nvidia* ]]; then
    for pkg in nvidia-gpu-firmware mesa-vulkan-drivers; do
        rum -yq reinstall --allowerasing $pkg ||
            rum -yq install --allowerasing $pkg
    done
    # Ensure nouveau vulkan ICDs exist
    (
        shopt -u nullglob
        ls /usr/share/vulkan/icd.d/nouveau_icd.*.json >/dev/null
    ) || {
        echo >&2 "::error::No nouveau vulkan ICDs found at /usr/share/vulkan/icd.d/nouveau_icd.*.json"
        exit 1
    }
fi

# Don't show the motd verification notice
rm -vf /etc/profile.d/verify_motd.sh

echo "Copying shared system files..."
cp -af /root/packages/installer/system_files/shared/. /


# Remove rakuos-welcome autostart for the live environment
rm -f /etc/xdg/autostart/rakuos-welcome.desktop

rm -rf /root/packages
