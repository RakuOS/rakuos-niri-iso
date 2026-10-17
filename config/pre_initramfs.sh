#!/usr/bin/env bash
set -exo pipefail

echo "Preparing initramfs for RakuOS Linux Live ISO"

# Swap the RakuOS kernel for a vanilla signed Fedora kernel so the live ISO
# boots with Secure Boot enabled. The installed system gets kernel-rakuos
# from the container image — this only affects the live boot environment.
# Every RakuOS kernel package the image can carry: both flavors (kernel-rakuos
# and the Steam Deck kernel-rakuos-deck), each x86-64 level, stable and
# staging, with all their subpackages.
kernel_pkgs=()
for flavor in rakuos rakuos-deck; do
    for isa in v2 v3 v4; do
        for channel in "" -staging; do
            for sub in "" -core -devel -devel-matched -modules -modules-core -modules-extra; do
                kernel_pkgs+=("kernel-${flavor}-${isa}${channel}${sub}")
            done
        done
    done
done
rum -y versionlock delete "${kernel_pkgs[@]}" 2>/dev/null || true
rum --setopt=protect_running_kernel=False -y remove "${kernel_pkgs[@]}" 2>/dev/null || true
(cd /usr/lib/modules && rm -rf -- ./*)
# --exclude: nothing may pull a RakuOS or deck kernel back into the live image.
rum -y --repo fedora,updates --setopt=tsflags=noscripts --exclude='kernel-rakuos*' install kernel kernel-core kernel-devel kernel-modules

rum -y --exclude='kernel-rakuos*' install \
    virtualbox-guest-additions \
    amd-gpu-firmware \
    amd-ucode-firmware \
    cirrus-audio-firmware \
    intel-audio-firmware \
    intel-gpu-firmware \
    linux-firmware \
    nvidia-gpu-firmware \
    qcom-wwan-firmware \
    atheros-firmware \
    b43-fwcutter \
    b43-openfwwf \
    brcmfmac-firmware \
    iwlegacy-firmware \
    iwlwifi-dvm-firmware \
    iwlwifi-mvm-firmware \
    libertas-firmware \
    mt7xxx-firmware \
    nxpwireless-firmware \
    realtek-firmware \
    tiwilink-firmware \
    atmel-firmware \
    zd1211-firmware \
    broadcom-wl \
    NetworkManager-wifi

KVER="$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -V | tail -1)"
akmods --force --kernels "$KVER"

kernel=$(find /usr/lib/modules -maxdepth 1 -type d -printf '%P\n' | grep .)
depmod "$kernel"
rum clean all -yq
