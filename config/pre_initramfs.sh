#!/usr/bin/env bash
set -exo pipefail

echo "Preparing initramfs for RakuOS Linux Live ISO"

# Swap the CachyOS kernel for a vanilla signed Fedora kernel so the live ISO
# boots with Secure Boot enabled. The installed system gets the CachyOS kernel
# from the container image — this only affects the live boot environment.
kernel_pkgs=(
    kernel-p03-v2
    kernel-p03-v2-core
    kernel-p03-v2-devel
    kernel-p03-v2-devel-matched
    kernel-p03-v2-modules
    kernel-p03-v2-modules-core
    kernel-p03-v2-modules-extra
    kernel-p03-v3
    kernel-p03-v3-core
    kernel-p03-v3-devel
    kernel-p03-v3-devel-matched
    kernel-p03-v3-modules
    kernel-p03-v3-modules-core
    kernel-p03-v3-modules-extra
    kernel-p03-v4
    kernel-p03-v4-core
    kernel-p03-v4-devel
    kernel-p03-v4-devel-matched
    kernel-p03-v4-modules
    kernel-p03-v4-modules-core
    kernel-p03-v4-modules-extra
    kernel-p03-v2-staging
    kernel-p03-v2-staging-core
    kernel-p03-v2-staging-devel
    kernel-p03-v2-staging-devel-matched
    kernel-p03-v2-staging-modules
    kernel-p03-v2-staging-modules-core
    kernel-p03-v2-staging-modules-extra
    kernel-p03-v3-staging
    kernel-p03-v3-staging-core
    kernel-p03-v3-staging-devel
    kernel-p03-v3-staging-devel-matched
    kernel-p03-v3-staging-modules
    kernel-p03-v3-staging-modules-core
    kernel-p03-v3-staging-modules-extra
    kernel-p03-v4-staging
    kernel-p03-v4-staging-core
    kernel-p03-v4-staging-devel
    kernel-p03-v4-staging-devel-matched
    kernel-p03-v4-staging-modules
    kernel-p03-v4-staging-modules-core
    kernel-p03-v4-staging-modules-extra
    kernel-rakuos-v2
    kernel-rakuos-v2-core
    kernel-rakuos-v2-devel
    kernel-rakuos-v2-devel-matched
    kernel-rakuos-v2-modules
    kernel-rakuos-v2-modules-core
    kernel-rakuos-v2-modules-extra
    kernel-rakuos-v3
    kernel-rakuos-v3-core
    kernel-rakuos-v3-devel
    kernel-rakuos-v3-devel-matched
    kernel-rakuos-v3-modules
    kernel-rakuos-v3-modules-core
    kernel-rakuos-v3-modules-extra
    kernel-rakuos-v4
    kernel-rakuos-v4-core
    kernel-rakuos-v4-devel
    kernel-rakuos-v4-devel-matched
    kernel-rakuos-v4-modules
    kernel-rakuos-v4-modules-core
    kernel-rakuos-v4-modules-extra
    kernel-rakuos-v2-staging
    kernel-rakuos-v2-staging-core
    kernel-rakuos-v2-staging-devel
    kernel-rakuos-v2-staging-devel-matched
    kernel-rakuos-v2-staging-modules
    kernel-rakuos-v2-staging-modules-core
    kernel-rakuos-v2-staging-modules-extra
    kernel-rakuos-v3-staging
    kernel-rakuos-v3-staging-core
    kernel-rakuos-v3-staging-devel
    kernel-rakuos-v3-staging-devel-matched
    kernel-rakuos-v3-staging-modules
    kernel-rakuos-v3-staging-modules-core
    kernel-rakuos-v3-staging-modules-extra
    kernel-rakuos-v4-staging
    kernel-rakuos-v4-staging-core
    kernel-rakuos-v4-staging-devel
    kernel-rakuos-v4-staging-devel-matched
    kernel-rakuos-v4-staging-modules
    kernel-rakuos-v4-staging-modules-core
    kernel-rakuos-v4-staging-modules-extra
)
rum -y versionlock delete "${kernel_pkgs[@]}" 2>/dev/null || true
rum --setopt=protect_running_kernel=False -y remove "${kernel_pkgs[@]}" 2>/dev/null || true
(cd /usr/lib/modules && rm -rf -- ./*)
rum -y --repo fedora,updates --setopt=tsflags=noscripts install kernel kernel-core kernel-devel kernel-modules

rum -y install \
--exclude=kernel-p03-v2 \
--exclude=kernel-p03-v2-core \
--exclude=kernel-p03-v2-devel \
--exclude=kernel-p03-v2-devel-matched \
--exclude=kernel-p03-v2-modules \
--exclude=kernel-p03-v2-modules-core \
--exclude=kernel-p03-v2-modules-extra \
--exclude=kernel-p03-v3 \
--exclude=kernel-p03-v3-core \
--exclude=kernel-p03-v3-devel \
--exclude=kernel-p03-v3-devel-matched \
--exclude=kernel-p03-v3-modules \
--exclude=kernel-p03-v3-modules-core \
--exclude=kernel-p03-v3-modules-extra \
--exclude=kernel-p03-v4 \
--exclude=kernel-p03-v4-core \
--exclude=kernel-p03-v4-devel \
--exclude=kernel-p03-v4-devel-matched \
--exclude=kernel-p03-v4-modules \
--exclude=kernel-p03-v4-modules-core \
--exclude=kernel-p03-v4-modules-extra \
--exclude=kernel-p03-v2-staging \
--exclude=kernel-p03-v2-staging-core \
--exclude=kernel-p03-v2-staging-devel \
--exclude=kernel-p03-v2-staging-devel-matched \
--exclude=kernel-p03-v2-staging-modules \
--exclude=kernel-p03-v2-staging-modules-core \
--exclude=kernel-p03-v2-staging-modules-extra \
--exclude=kernel-p03-v3-staging \
--exclude=kernel-p03-v3-staging-core \
--exclude=kernel-p03-v3-staging-devel \
--exclude=kernel-p03-v3-staging-devel-matched \
--exclude=kernel-p03-v3-staging-modules \
--exclude=kernel-p03-v3-staging-modules-core \
--exclude=kernel-p03-v3-staging-modules-extra \
--exclude=kernel-p03-v4-staging \
--exclude=kernel-p03-v4-staging-core \
--exclude=kernel-p03-v4-staging-devel \
--exclude=kernel-p03-v4-staging-devel-matched \
--exclude=kernel-p03-v4-staging-modules \
--exclude=kernel-p03-v4-staging-modules-core \
--exclude=kernel-p03-v4-staging-modules-extra \
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
