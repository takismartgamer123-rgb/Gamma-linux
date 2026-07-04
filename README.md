**Gamma Linux v2.6.5 — Tank Edition**
​Maximum Power, Minimum RAM
​Alpha failed. Beta crashed. Gamma survives. Because no PC deserves to die!
​By: Taki | 17 Years Old | From Guelma, Algeria
Special Dedication: Dedicated to my father, Fateh
Special Thanks: To Jennase Bryan (First Official Tester and QA Hero)
​0. CRITICAL WARNING — READ THIS OR LOSE WINDOWS
​If you plan to Dual-Boot alongside Windows 10 or Windows 11, you MUST disable these features in Windows BEFORE booting the Gamma Linux USB:
​Disable Fast Startup: Go to Control Panel -> Power Options -> Choose what the power buttons do -> Uncheck "Turn on fast startup".
​Disable Hibernation: Open Command Prompt (CMD) as Administrator and run the command: powercfg /h off
​Why? If left enabled, Windows mounts the drives in a locked state. This will prevent Linux from safely partitioning and can cause massive data loss. Be smart, protect your data!
​1. WHAT IS GAMMA LINUX?
​Gamma Linux is an ultra-minimalistic, independent meta-distribution built on top of robust Ubuntu 22.04 LTS and Debian 12 Bookworm bases.
​Our core mission is absolute User Freedom and environmental sustainability: breathing pristine, lightning-fast life back into older computers (from 512MB to 2GB+ RAM) that modern operating systems have completely abandoned.
​Absolute Zero Bloat Policy: No forced web browsers, no telemetry, no background metrics tracking.
​No Snaps, No Flatpaks: Clean, pure, and native packages only.
​Size: Compressed using ultra-high-ratio ZSTD-19 to keep the core OS footprint exceptionally lightweight.
​2. EDITIONS MATRIX — v2.6.5 TANK
​Gamma Legacy-32 (32-bit): Built on Debian 12 for 512MB RAM machines using Enlightenment (E17).
​Gamma Lite-Ghost (64-bit): Built on Ubuntu 22.04 for 1GB RAM machines using Minimal Openbox + Tint2.
​Gamma Pro-MaxMini (64-bit): Built on Ubuntu 22.04 for 2GB+ RAM machines using Openbox + EarlyOOM.
​Global Visuals: Customized Materia-Dark interface theme paired with premium Papirus-Dark icons.
​Live System Credentials: User is "gamma" and Password is "gamma".
​3. UNIVERSAL BOOT ENGINE v2 (Hardware Detection)
​Gamma Linux Tank Edition features a custom built-in Universal Hardware Detection Script (99gamma-auto) that triggers automatically during boot. If it detects older, historically stubborn hardware (such as legacy laptops, older Intel architectures, or early integrated AMD/Nvidia chips between 2010–2015), it automatically injects safe fallback kernel parameters (noapic, nolapic, acpi=off, nomodeset, intel_idle.max_cstate=1) to prevent hardware freezes.
​4. QUICK INSTALLATION GUIDE
​STEP 1: Flash the ISO
​Recommended: Use Rufus written strictly in DD Image Mode (perfect for bypass-sensitive legacy BIOS systems), or deployment tools like Ventoy / BalenaEtcher.
​STEP 2: Boot and Run
​Boot into the USB media and choose Gamma Auto-Detect or Live Boot from the menu.
​The system logs automatically into the live user "gamma".
​Launch the graphical installer framework located directly on the desktop layout (Calamares for Debian / Ubiquity for Ubuntu bases).
​STEP 3: Automated Post-Install Purge
​On Ubuntu-based editions (Lite-Ghost & Pro-MaxMini), a custom background systemd service (gamma-cleanup) triggers automatically 15 seconds after your first successful post-install desktop boot to purge the deployment installer libraries, freeing up local disk space instantly.
​5. HARDWARE REQUIREMENTS
​Legacy-32: 512MB RAM, 4GB Storage, 32-bit or 64-bit Intel/AMD CPU.
​Lite-Ghost: 1GB RAM, 6GB Storage, 64-bit CPU.
​Pro-MaxMini: 2GB+ RAM, 8GB Storage, 64-bit CPU.
​6. CHECKSUMS AND VERIFICATION
​Always verify your ISO downloads to ensure no corruption occurred during transit. Inside your download directory, run: sha256sum -c SHA256SUMS.txt
​7. SUPPORT THE PROJECT (DistroWatch)
​Help Gamma Linux reach more users across the global open-source community! Vote for us directly on DistroWatch through this link:
https://distrowatch.com/dwres-mobile.php?waitingdistro=1101&resource=links#new
​8. CONTACT AND COMMUNITY
​Telegram Channel: https://t.me/GammaLinuxDZ (Main Announcements and Support)
​Messenger Community Chat (Highly Recommended): https://m.me/j/AbahTOn_gqLy8R3k/?send_source=gc%3Acopy_invite_link_t
​Official Repository: https://github.com/takismartgamer123-rgb/Gamma-linux
​Made with pure rage, coffee, and a rock-solid GitHub Actions CI/CD framework in Algeria 🇩🇿
