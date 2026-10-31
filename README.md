# Gamma Linux

> **No PC deserves to die.**
>
> Lightweight, free and open-source Linux focused on giving older computers another useful life.
>
> **Made in Algeria 🇩🇿**

Gamma Linux is a small, hardware-conscious Linux distribution project. It combines established Debian/Ubuntu bases with Gamma-specific configuration, live-system integration and ISO-building tools.

- Website: https://gamma-linux.is-local.org/
- Source code: https://github.com/takismartgamer123-rgb/Gamma-linux
- Releases: https://github.com/takismartgamer123-rgb/Gamma-linux/releases
- DistroWatch: https://distrowatch.com/dwres-mobile.php?waitingdistro=1101&resource=links#new

## Project status

The latest published GitHub release is named **Gamma Linux v2.7.1 — Warden**. Check the [Releases page](https://github.com/takismartgamer123-rgb/Gamma-linux/releases) for the exact ISO files currently available, release notes and checksums.

The repository contains build scripts for three edition targets. A build target being present in the source tree does **not** mean that a ready-to-download ISO for that edition is published. Always check the release assets before downloading.

## Editions and build targets

| Edition | Base configured by the build scripts | Architecture | Intended direction |
|---|---|---|---|
| **Legacy** | Debian 12 Bookworm | i386 | Compatibility with older 32-bit hardware |
| **Lite** | Ubuntu 22.04 Jammy | amd64 | Lightweight desktop for modest 64-bit systems |
| **Pro** | Ubuntu 22.04 Jammy | amd64 | A more complete desktop for systems with more resources |

These are the base-system settings in the current build scripts. Hardware requirements and included software can change between builds; consult the relevant release notes rather than treating the table as fixed minimum specifications.

## Core design

- **Lightweight by design:** avoid unnecessary services and software.
- **Older-hardware focus:** keep compatibility and resource use in mind.
- **Open source:** build scripts and project-specific components are maintained in this repository.
- **User-respecting defaults:** no Snap or Flatpak is installed by default as part of the project's stated minimal approach.
- **Hybrid boot media:** the ISO builder prepares BIOS and UEFI boot entries. Legacy builds also check for an IA32 EFI loader.

## Current technical layout

The current scripts describe the following build architecture:

| Component | Current implementation |
|---|---|
| Legacy base | Debian Bookworm, i386 |
| Lite / Pro base | Ubuntu Jammy, amd64 |
| Legacy live filesystem | Debian Live-style `live/` directory |
| Lite / Pro live filesystem | Casper-style `casper/` directory |
| Live filesystem format | SquashFS |
| BIOS boot | ISOLINUX |
| UEFI boot | GRUB EFI image |
| ISO creation | xorriso |
| Memory optimization | Edition-specific ZRAM configuration |

The exact desktop, package selection and installer behavior should be checked against the scripts and release notes for the build you are using.

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

### Requirements

The build process uses Bash, debootstrap, xorriso, Syslinux/ISOLINUX, SquashFS tooling and GRUB EFI components. The QEMU test script also requires `qemu-system-x86_64`; OVMF firmware is needed for its optional UEFI x86_64 boot test.

Install the dependencies appropriate for your host distribution before starting. Package names can differ between distributions.

### Build sequence

The repository's numbered scripts define the build workflow:

1. `scripts/01-prepare.sh` — prepares the base chroot.
2. `scripts/02-install-packages.sh` — installs the edition packages.
3. `scripts/03-install-gamma.sh` — installs Gamma-specific components.
4. `scripts/04-configure.sh` — configures the system and completes chroot preparation.
5. `scripts/05-build-squashfs.sh` — creates the compressed live filesystem.
6. `scripts/06-build-efi.sh` — prepares EFI boot files.
7. `scripts/07-build-iso.sh` — validates the ISO tree and creates the hybrid ISO.
8. `scripts/08-test.sh` — checks ISO structure and attempts QEMU BIOS and, when OVMF is available, UEFI x86_64 boot tests.

Run the scripts from the repository root, in order, using the same edition argument:

```bash
sudo bash scripts/01-prepare.sh legacy
sudo bash scripts/02-install-packages.sh legacy
sudo bash scripts/03-install-gamma.sh legacy
sudo bash scripts/04-configure.sh legacy
sudo bash scripts/05-build-squashfs.sh legacy
sudo bash scripts/06-build-efi.sh legacy
sudo bash scripts/07-build-iso.sh legacy
bash scripts/08-test.sh legacy
```

Replace `legacy` with `lite` or `pro` when building those targets. Check each script before running it and follow any prerequisites it reports.

> **Destructive build warning:** `01-prepare.sh` unmounts and removes the repository's `chroot/`, `iso/` and `output/` directories before preparing a new build. Back up anything important in those directories first. Do not run it if you need to preserve a previous build.

The ISO build script checks required files, validates the EFI image and SquashFS, and verifies the resulting ISO contents. The test script performs automated boot attempts; passing those checks is not a substitute for testing the live system and installer on real hardware.

## Testing and bug reports

Testing on older physical hardware is especially valuable. When reporting a bug, include:

- PC manufacturer and model
- CPU model and architecture
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
