# Gamma Linux

> **No PC deserves to die.**
>
> Lightweight, free and open-source Linux focused on giving older computers another useful life.
>
> **Made in Algeria 🇩🇿**

Gamma Linux is a lightweight Linux distribution project for older computers. Its target root filesystems are built from Debian using a manual chroot workflow, then assembled into hybrid bootable ISO images with SquashFS, GRUB, ISOLINUX and xorriso.

- Website: https://gamma-linux.is-local.org/
- Source code: https://github.com/takismartgamer123-rgb/Gamma-linux
- Releases: https://github.com/takismartgamer123-rgb/Gamma-linux/releases
- DistroWatch: https://distrowatch.com/dwres-mobile.php?waitingdistro=1101&resource=links#new

## Project status

The latest published GitHub release currently listed by the project is **Gamma Linux v2.7.1 — Warden**. Check the [Releases page](https://github.com/takismartgamer123-rgb/Gamma-linux/releases) for the exact ISO files, release notes and checksums that are actually available.

The Debian migration changes the source build configuration. Existing release assets are not rebuilt or retroactively changed by these source updates.

## Editions and target bases

| Edition | Target base | Architecture | Purpose |
|---|---|---|---|
| **Legacy-32** | Debian 12 Bookworm | i386 | Compatibility with older 32-bit hardware |
| **Lite-Ghost** | Debian 13 Trixie | amd64 | Lightweight desktop for modest 64-bit systems |
| **Pro-MaxMini** | Debian 13 Trixie | amd64 | More complete desktop for systems with additional resources |

The exact installed package set and hardware behavior can change between builds. Consult the release notes for published images; the table above describes the current source build targets.

## Build architecture

Gamma uses a **manual chroot-to-ISO pipeline**. It does not use Ubuntu Casper and does not use `live-build`.

| Stage | Implementation |
|---|---|
| Base filesystem | `debootstrap` creates a Debian chroot |
| Edition configuration | `build/profiles/*.conf` |
| Shared build logic | Numbered Bash scripts under `scripts/` |
| Live boot integration | Debian `live-boot` and `live-config` |
| Live filesystem | `mksquashfs` creates `iso/live/filesystem.squashfs` |
| Kernel/initramfs | Debian kernel and `initramfs-tools` |
| BIOS boot | ISOLINUX |
| UEFI boot | GRUB EFI, with IA32 loader required for Legacy-32 |
| ISO assembly | `xorriso` |

All editions use one Debian Live layout:
- Kernel: `/live/vmlinuz`
- Initramfs: `/live/initrd.lz` (the established Gamma filename; it is copied from Debian's generated initramfs)
- Compressed root filesystem: `/live/filesystem.squashfs`
- Kernel command-line parameter: `boot=live`

The Debian Live packages are installed inside the target chroot: `live-boot`, `live-boot-initramfs-tools`, `live-config` and `live-config-systemd`. The build host and the target operating system are separate: the current GitHub Actions workflow may run on Ubuntu, but it bootstraps Debian target filesystems.

For the full pipeline, profile variables, host dependencies and troubleshooting, read [docs/build-system.md](docs/build-system.md).

## Core design

- **Lightweight by design:** avoid unnecessary packages and background services.
- **Older-hardware focus:** keep compatibility and resource use in mind.
- **Open source:** build scripts and Gamma-specific components are maintained in this repository.
- **User-respecting defaults:** Snap and Flatpak are not installed by default as part of the project's minimal approach.
- **Hybrid boot media:** BIOS and UEFI boot paths are prepared by the manual ISO builder.

## Download and verify

1. Open [Gamma Linux Releases](https://github.com/takismartgamer123-rgb/Gamma-linux/releases).
2. Select the release and edition that match your hardware.
3. Read the release notes, including known issues and login details if provided.
4. If a checksum file is published with the ISO, verify it before writing the image to USB.

Example SHA-256 verification:

```bash
sha256sum Gamma-Linux.iso
```

Compare the output with the checksum published by the project. Do not assume a checksum exists if the release does not provide one.

## Installation and dual-boot safety

Back up important files before changing partitions or installing any operating system. Selecting the wrong disk or partition can cause permanent data loss.

If you plan to install Gamma alongside Windows:

- Disable Windows Fast Startup.
- Disable hibernation from an Administrator terminal with `powercfg /h off`.
- Shut Windows down fully before booting the installer.
- Do not resize, format or mount a Windows partition that is hibernated or in an unsafe state.

Boot the USB and test the live environment first. Use the installer supplied by that particular ISO and read every partitioning and bootloader change before confirming it. Installer availability and behavior may differ between editions and releases.

## Building from source

Read [Build System Documentation](docs/build-system.md) before starting. The build scripts modify and remove generated build directories.

The standard sequence is:

```bash
bash scripts/01-prepare.sh <pro|lite|legacy>
bash scripts/02-install-packages.sh <pro|lite|legacy>
bash scripts/03-install-gamma.sh
bash scripts/04-configure.sh <pro|lite|legacy>
bash scripts/05-build-squashfs.sh <pro|lite|legacy>
bash scripts/06-build-efi.sh <pro|lite|legacy>
bash scripts/07-build-iso.sh <pro|lite|legacy>
bash scripts/08-test.sh <pro|lite|legacy>
```

Run all commands from the repository root. The scripts use `sudo` for privileged filesystem and mount operations; do not run the entire sequence inside an already-root shell unless you have deliberately adapted the scripts.

> **Destructive build warning:** `scripts/01-prepare.sh` unmounts and removes the generated `chroot/`, `iso/` and `output/` directories before preparing a new build. Move anything you need to keep outside those paths first.

The automated QEMU checks validate boot records and attempt BIOS and UEFI x86_64 boots. They do not replace testing the live desktop, installer, networking, graphics, sound or hardware on real machines. The Legacy IA32 EFI loader is checked in the ISO tree but is not emulated by the x86_64 QEMU test.

## Testing and bug reports

Testing on older physical hardware is especially valuable. When reporting a bug, include:

- PC manufacturer and model
- CPU model and architecture (32-bit or 64-bit)
- RAM amount
- Storage type and capacity
- Gamma edition and exact release/build
- BIOS or UEFI mode
- Steps to reproduce the issue
- Relevant logs or clear screenshots

For installer or partitioning issues, include only the disk details needed to understand the problem. **Never publish passwords, personal files, serial numbers or other private information.**

Open a report in the [GitHub Issues](https://github.com/takismartgamer123-rgb/Gamma-linux/issues) section.

## Contributing

Bug reports, reproducible fixes, documentation improvements and hardware testing are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a change.

## License

The repository's `LICENSE.md` identifies the project-specific Gamma components as MIT-licensed. Gamma Linux also includes or depends on software under other upstream licenses. Those components remain governed by their respective licenses; consult their package metadata and upstream notices before redistribution.

## Acknowledgments

Thanks to everyone testing Gamma Linux, reporting bugs and helping older hardware stay useful.

**No PC deserves to die.**  
**Made in Algeria 🇩🇿**
