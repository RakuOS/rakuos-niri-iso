#!/usr/bin/env bash
set -exo pipefail

echo "Preparing initramfs for RakuOS Linux Live ISO"

# Swap the CachyOS kernel for a vanilla signed Fedora kernel so the live ISO
# boots with Secure Boot enabled. The installed system gets the CachyOS kernel
# from the container image — this only affects the live boot environment.
kernel_pkgs=(
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
)
dnf -y versionlock delete "${kernel_pkgs[@]}" 2>/dev/null || true
dnf --setopt=protect_running_kernel=False -y remove "${kernel_pkgs[@]}" 2>/dev/null || true
(cd /usr/lib/modules && rm -rf -- ./*)
dnf -y --repo fedora,updates --setopt=tsflags=noscripts install kernel kernel-core kernel-devel kernel-modules

dnf -y install \
    --exclude=kernel-p03 \
    --exclude=kernel-p03-core \
    --exclude=kernel-p03-devel \
    --exclude=kernel-p03-devel-matched \
    --exclude=kernel-p03-modules \
    --exclude=kernel-p03-modules-core \
    --exclude=kernel-p03-modules-extra \
    --exclude=kernel-cachyos \
    --exclude=kernel-cachyos-core \
    --exclude=kernel-cachyos-devel \
    --exclude=kernel-cachyos-devel-matched \
    --exclude=kernel-cachyos-modules \
    --exclude=kernel-cachyos-modules-core \
    --exclude=kernel-cachyos-modules-extra \
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
dnf clean all -yq
