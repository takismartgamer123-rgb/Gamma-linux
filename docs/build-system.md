# Gamma Linux build system

This document describes the Debian migration build path in this branch. It is a hand-built chroot and ISO pipeline, not a `live-build` configuration.

## 1. Target matrix

| Gamma target | Debian suite | Architecture | Kernel package | Live boot |
|---|---|---|---|---|
| `pro` | Debian 13 Trixie | `amd64` | `linux-image-amd64` | Debian Live |
| `lite` | Debian 13 Trixie | `amd64` | `linux-image-amd64` | Debian Live |
| `legacy` | Debian 12 Bookworm | `i386` | `linux-image-686-pae` | Debian Live |

The edition profiles are stored in `build/profiles/`. They define the Debian suite, architecture, mirrors, APT components, kernel package, live directory, boot parameter, hostname and memory tuning values.

The profile loader in `scripts/lib/profile.sh` validates the supported target tuples. Shared scripts should consume these variables instead of adding new hard-coded edition switches.

## 2. Build host versus target system

The build host only supplies tools that manipulate the filesystem and produce the ISO. The root filesystem inside `chroot/` is Debian.

The current GitHub Actions workflow uses an Ubuntu runner as a build host. That does **not** make Gamma Lite or Pro Ubuntu-based: `debootstrap` creates Debian Trixie chroots for those targets, and a Debian Bookworm chroot for Legacy.

### Host tools

Install the equivalent packages for your build-host distribution:

- Bash, sudo, coreutils, findutils, grep, sed, gawk
- `debootstrap`
- `initramfs-tools` (provides `lsinitramfs` used by the QA stage)
- `squashfs-tools`
- `xorriso`
- `isolinux` and `syslinux-common`
- `grub-common`, `grub-pc-bin`, `grub-efi-amd64-bin`, `grub-efi-ia32-bin`
- `dosfstools`, `mtools`
- `qemu-system-x86` and `ovmf` for automated boot checks
- `build-essential`, `cmake`, `pkg-config`, `libefl-all-dev` and `libedje-bin` to build Gamma CC and compile the Edje theme (`edje_cc`)

The exact host package names may differ between distributions.

## 3. Target APT configuration

`scripts/01-prepare.sh` reads the selected profile and bootstraps its Debian suite with `debootstrap`. It then writes the target APT sources using the profile's Debian mirror, security mirror and components:

- `main`
- `contrib`
- `non-free-firmware`

The source entries include the suite, its updates pocket and the Debian security pocket. Do not add Ubuntu PPAs, `add-apt-repository`, Ubuntu language-pack packages or Ubuntu meta-packages to this Debian target path.

Locales are generated inside the chroot from `locales` using `/etc/locale.gen`.

## 4. Debian Live integration

All current target editions use Debian's Live components:

- `live-boot`
- `live-boot-initramfs-tools`
- `live-config`
- `live-config-systemd`

The systemd backend is installed because the target root filesystem uses systemd. The initramfs is generated inside the target chroot by `update-initramfs`.

Gamma writes `/etc/live/config.conf` from the selected edition profile so the live session does not fall back to Debian's generic defaults:

- `LIVE_HOSTNAME` uses the edition hostname (`gamma-pro`, `gamma-lite` or `gamma-legacy`).
- `LIVE_USERNAME=gamma` creates the Gamma live user.
- `LIVE_USER_FULLNAME=Gamma Linux User` sets the display name.

Because this build uses `--no-install-recommends`, the packages `user-setup` and `sudo` are installed explicitly. They are recommended by Debian's `live-config` package and are needed for creating the configured live user and granting that user sudo privileges. The `lightdm` live-config component enables graphical autologin.

The Debian Live user-setup component supplies its documented default live password (`live`) unless a project-specific password hook is added. Treat this as a live-session credential, not a secure installed-user password; installation creates the installed system's user account separately.

Every edition uses the same ISO layout and boot parameter:

- ISO directory: `iso/live/`
- Kernel: `iso/live/vmlinuz`
- Initramfs: `iso/live/initrd.lz`
- Root filesystem: `iso/live/filesystem.squashfs`
- Kernel parameter: `boot=live`

The `initrd.lz` name is retained for compatibility with the existing Gamma boot menu and ISO layout. The file is copied from Debian's generated initramfs; the filename alone does not imply that the image was recompressed with LZ.

Do not add Casper-specific initramfs hooks or use `boot=casper`. Do not replace this project-specific pipeline with `live-build` unless the build architecture is intentionally redesigned.

## 5. Build stages

Run the stages from the repository root, in order, with the same edition name.

| Script | Responsibility |
|---|---|
| `01-prepare.sh` | Load edition profile, clean generated work directories, bootstrap Debian chroot, write APT sources, mount host virtual filesystems |
| `02-install-packages.sh` | Verify Debian suite/architecture, install desktop, kernel, installer and Debian Live packages, generate initramfs |
| `03-install-gamma.sh` | Build and install Gamma Control Center and compile/install the Gamma Edje theme |
| `04-configure.sh` | Apply Gamma identity, LightDM, Calamares branding, ZRAM and sysctl tuning |
| `05-build-squashfs.sh` | Validate Debian Live initramfs integration, clean transient state, create SquashFS and copy kernel/initramfs |
| `06-build-efi.sh` | Build GRUB x86_64 and IA32 EFI loaders and the EFI System Partition image |
| `07-build-iso.sh` | Prepare ISOLINUX files, validate the ISO tree and create a hybrid ISO with xorriso |
| `08-test.sh` | Validate ISO contents and boot records; attempt QEMU BIOS and UEFI x86_64 boots |

Example for Trixie Pro:

```bash
bash scripts/01-prepare.sh pro
bash scripts/02-install-packages.sh pro
bash scripts/03-install-gamma.sh
bash scripts/04-configure.sh pro
bash scripts/05-build-squashfs.sh pro
bash scripts/06-build-efi.sh pro
bash scripts/07-build-iso.sh pro
bash scripts/08-test.sh pro
```

For Lite, replace `pro` with `lite`. For the Bookworm Legacy target, use `legacy`.

### Destructive cleanup

**Important:** `scripts/01-prepare.sh` unmounts and deletes the generated repository directories `chroot/`, `iso/` and `output/` before starting a clean build. Move any previous build artifacts you need to keep outside those directories first.

The scripts use `sudo` for privileged mount, chroot and filesystem operations. Run them from a normal user shell with sudo access; do not blindly execute the entire build as root.

## 6. Boot support and limits

The ISO builder prepares:

- BIOS boot through ISOLINUX.
- UEFI x86_64 through GRUB.
- IA32 UEFI through GRUB for the Legacy target.
- An EFI System Partition image embedded in the hybrid ISO.
- SquashFS compressed with XZ by the current builder.

The automated test script checks BIOS and UEFI x86_64 boot records and attempts QEMU boots. It also checks that the Legacy ISO contains `EFI/BOOT/BOOTIA32.EFI`; it does not currently emulate IA32 UEFI.

A QEMU process surviving until the timeout is treated by the current smoke test as a boot attempt pass. This is not proof that the desktop reached a usable login session. Test the live desktop, Calamares, network, graphics and real hardware separately before publishing an image.

## 7. Migration rules

When changing the build system:

1. Put suite, architecture, mirrors, kernel choice and edition tuning in `build/profiles/<edition>.conf`.
2. Keep shared pipeline logic in `scripts/` and load the profile through `scripts/lib/profile.sh`.
3. Keep Debian Live boot files and boot parameters consistent across `05` to `08`.
4. Update this document and the top-level README whenever a build stage, package set or boot layout changes.
5. Test all three edition profiles. A successful shell syntax check is not an ISO build, and a successful ISO build is not a hardware compatibility result.
