# Gamma Linux v2.7 — Warden

Maximum Power, Minimum RAM ♾️

Alpha failed. Beta crashed. Gamma survives. Because no PC deserves to die.

By: Taki | From Guelma, Algeria
Special Dedication: Dedicated to my father, Fateh

--------------------------------------------------
CRITICAL WARNING — READ THIS BEFORE DUAL-BOOTING WITH WINDOWS
--------------------------------------------------

If you plan to dual-boot alongside Windows 10 or Windows 11, you MUST disable these Windows features BEFORE booting the Gamma Linux USB:

- Disable Fast Startup: Control Panel → Power Options → Choose what the power buttons do → Uncheck "Turn on fast startup".
- Disable Hibernation: Open an Administrator Command Prompt (CMD) and run:

  powercfg /h off

Why this matters: When Fast Startup or hibernation is enabled, Windows saves the system state and leaves drives in a hibernated/locked state. Linux mounting or partitioning a hibernated Windows filesystem can cause corruption or irreversible data loss. Disabling hibernation and Fast Startup ensures drives are cleanly unmounted and safe for partitioning and installation.

--------------------------------------------------
WHAT IS GAMMA LINUX?
--------------------------------------------------

Gamma Linux is a lightweight, free, open-source meta-distribution focused on reviving older PCs and offering a minimal, privacy-respecting desktop experience. Version 2.7 — Warden builds on the project's proven foundations and modern base packages while remaining small, focused, and easy to install.

Our mission: breathe practical life back into older hardware while keeping user freedom, transparency, and low resource usage at the core of every decision.

Key principles

- Ultra-light by default: minimal services and a strict zero-bloat policy.
- Free and open-source: source and tooling remain open; we welcome community contributions.
- Compatibility-first: tuned for older CPUs, small RAM footprints, and limited storage.

--------------------------------------------------
EDITIONS (current)
--------------------------------------------------

Gamma is available in three curated editions to fit a range of legacy hardware and user needs:

1. Gamma Legacy-32
   - 32-bit edition aimed at very old hardware. Optimized for systems with very low RAM and older CPUs.
2. Gamma Lite-Ghost
   - Lightweight 64-bit edition targeted at modest machines (around 1GB RAM). Minimal window manager + small toolset.
3. Gamma Pro-MaxMini
   - More feature-complete 64-bit edition for slightly newer legacy hardware (2GB+ RAM), tuned for snappy responsiveness while remaining lightweight.

Choose the edition that matches your machine's RAM and CPU architecture. See Hardware Requirements below.

--------------------------------------------------
INSTALLATION GUIDE (overview)
--------------------------------------------------

1) Verify your download

Always verify ISO checksums after download. Example:

  sha256sum -c SHA256SUMS.txt

2) Create installation media

Recommended tools:
- Rufus (use DD image mode for the most compatible result on legacy BIOS systems)
- BalenaEtcher
- Ventoy

3) Boot the media

Boot from the USB drive and select the Live or Auto-Detect entry. The live session logs into the default user when required for the live environment.

4) Install

Follow the included graphical installer. For Debian-based editions Calamares may be used; follow on-screen options to partition and install.

5) Post-install

On some editions a lightweight post-install cleanup service will remove non-essential install-time tooling on first boot. After install, reboot into the installed system and verify hardware and display settings.

Notes

- If you are dual-booting with Windows, follow the Critical Warning above before starting.
- We intentionally avoid Snap/Flatpak by default to keep the system minimal and predictable.

--------------------------------------------------
HARDWARE REQUIREMENTS (guideline)
--------------------------------------------------

- Gamma Legacy-32: Suitable for very old systems; expect low RAM and minimal storage usage (check edition image notes).
- Gamma Lite-Ghost: Recommended for ~1GB RAM machines.
- Gamma Pro-MaxMini: Recommended for 2GB+ RAM machines.

Always check the ISO release notes for exact minimums for a given build.

--------------------------------------------------
CHECKSUMS AND VERIFICATION
--------------------------------------------------

We publish SHA256 checksums alongside release ISOs. Verify downloads before flashing to protect against corruption and tampering.

--------------------------------------------------
BUG REPORTING
--------------------------------------------------

When opening a bug report, please provide as much of the following information as possible to help us reproduce and diagnose the issue:

- PC model (manufacturer and model)
- CPU model
- RAM amount
- Storage type and size (HDD/SSD and capacity)
- Gamma edition and exact version (e.g. Gamma Pro-MaxMini v2.7 Warden)
- Steps to reproduce the problem
- A photo or a clear description of the problem (screenshots are very helpful)
- Any relevant logs (dmesg, Xorg/Wayland logs, installer logs) if available

Create a new issue in this repository and include the above details. If the issue involves disk/installation problems, avoid sharing sensitive data — include only the pieces of system information needed to reproduce the bug.

--------------------------------------------------
FEEDBACK & CONTACT
--------------------------------------------------

Send general feedback, questions, or media to: takismartgamer123@gmail.com

Join the community channels in the main repo for announcements and support. Links:
- Telegram: https://t.me/GammaLinuxDZ
- Messenger community: https://m.me/j/AbahTOn_gqLy8R3k/?send_source=gc%3Acopy_invite_link_t

--------------------------------------------------
ROADMAP
--------------------------------------------------

Planned focus areas for the 2.7 Warden cycle (high level):

- Improved hardware detection and older GPU support
- Smaller, more robust installer flows for legacy BIOS systems
- Continued maintenance of base packages and security updates

For a detailed roadmap and milestones, check the project issues and pinned discussions in this repository.

--------------------------------------------------
PROJECT PHILOSOPHY
--------------------------------------------------

Gamma Linux focuses on practical sustainability: extend the useful life of older hardware, keep systems transparent, and avoid unnecessary complexity. We value small, auditable components and community collaboration.

--------------------------------------------------
DEVELOPMENT & TESTING WORKFLOW
--------------------------------------------------

- Work is tracked in issues. Propose changes with a clear issue referencing the target area.
- Branching: create topic branches named feature/<short-description> or fix/<short-description> off the default branch.
- Pull requests: Open a PR referencing the related issue. Provide a clear description, testing steps, and the expected impact.
- CI: We use GitHub Actions for automated checks where applicable. Keep changes small and focused for easier review.
- Local testing: build and run the ISO in a VM (QEMU/VirtualBox) and on one non-critical test machine before wider testing. Document hardware used for testing in PR descriptions.

Testing checklist for contributors

- Does the ISO boot in UEFI and legacy BIOS (if expected)?
- Does the installer complete without errors on the test device?
- Are core services starting as expected?
- Do packaging changes include checksums and version bumps where relevant?

--------------------------------------------------
SUPPORT THE PROJECT (DistroWatch)
--------------------------------------------------

Vote for Gamma Linux on DistroWatch to help reach more users:

https://distrowatch.com/dwres-mobile.php?waitingdistro=1101&resource=links#new

--------------------------------------------------
LICENSE
--------------------------------------------------

Gamma Linux is free and open-source. See the LICENSE file in this repository for details.

--------------------------------------------------
ACKNOWLEDGMENTS
--------------------------------------------------

Special thanks to our testers and the wider open-source community. Made in Algeria — with a love of breathing life into old PCs.
