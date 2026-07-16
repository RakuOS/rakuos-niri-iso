# RakuOS NIRI ISO

This repository builds the NIRI live ISO for RakuOS Linux.

It is the ISO-side companion to the `rakuos-niri` image repository and is built in GitLab using [RakuForge](https://gitlab.com/rakuos/iso/rakuos-forge), the RakuOS-maintained fork of uBlue's Titanoboa.

## Purpose

This repo exists to keep ISO-specific logic separate from the desktop image repo.

It owns:

- NIRI ISO pipeline configuration
- live ISO customization hooks
- post-rootfs and pre-initramfs scripts
- edition-specific ISO naming and release behavior

It does not own the desktop container image itself. That comes from:

- `registry.gitlab.com/rakuos/images/rakuos-niri`
- `registry.gitlab.com/rakuos/images/rakuos-niri/nvidia`

## Branches

The pipeline is branch-aware and follows the same release lanes as the rest of RakuOS:

- `main` -> stable / `latest`
- `staging` -> next Fedora release lane
- `rawhide` -> rolling development lane
- `rakuosel` -> future enterprise / EL lane

## Pipeline Behavior

GitLab CI builds two ISO variants:

- standard
- nvidia

The pipeline currently supports:

- branch-aware image tag selection
- branch-aware builder distro selection
- optional upload to the RakuOS server
- optional upload to SourceForge
- checksum artifacts stored in GitLab

### Current Inputs

The manual pipeline form exposes these inputs:

- `rakuos-server-upload`
- `sourceforge-upload`

## RakuForge

The pipeline clones and uses:

- `https://gitlab.com/rakuos/iso/rakuos-forge.git`

RakuForge is used to assemble the live ISO from the corresponding RakuOS bootc image while carrying the RakuOS-specific CI behavior needed for GitLab.

Upstream credit:

- https://github.com/ublue-os/titanoboa

## Repo Layout

- [config/configure-iso.sh](/var/home/tohur/Documents/Projects/rakuos-niri-iso/config/configure-iso.sh)
- [config/pre_initramfs.sh](/var/home/tohur/Documents/Projects/rakuos-niri-iso/config/pre_initramfs.sh)
- [.gitlab-ci.yml](/var/home/tohur/Documents/Projects/rakuos-niri-iso/.gitlab-ci.yml)

## Local Notes

This repo is primarily intended to run through GitLab CI. For local debugging, the same hook scripts can be used with RakuForge directly through its `Justfile`.
