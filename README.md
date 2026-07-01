
****Gamma Linux v2.1 - Royal Edition Ultra-Lite****

Maximum Power, Minimum RAM ♾️🇩🇿

Alpha failed. Beta crashed. Gamma survives.
Because no PC deserves to die.

BY: Taki | 17 Years Old | From Guelma, Algeria
SPECIAL DEDICATION: To my father, Fateh ∞

 ****0. CRITICAL WARNING - READ THIS OR LOSE WINDOWS****

!!! IF YOU DUAL BOOT WITH WINDOWS 10/11!!!
You MUST disable these in Windows BEFORE installing Gamma:

1. Fast Startup: Control Panel -> Power Options -> Choose what power buttons do -> Uncheck 'Fast Startup'
2. Hibernation: Open CMD as Admin -> Run: powercfg /h off

WHY? If you don't, Windows will lock your disk. You will lose data.
Gamma is not responsible for corrupted Windows partitions. BE SMART.

 ***1. WHAT IS GAMMA LINUX?***

Gamma is an Ubuntu/Debian based distro with LXQt 1.4 Royal Edition.
Goal: Modern Linux for 512MB RAM PCs that others threw away.
No Snap. No Flatpak. No Bloat. Only Speed.

 ***2. EDITIONS & SIZES - v2.1 ROYAL***

1. Gamma Legacy 32 766 MB | 32-bit | For 512MB RAM | Debian Base
2. Gamma Lite Ghost 1.75 GB | 64-bit | For 1GB RAM | Ubuntu Base
3. Gamma Fatih Pro 1.76 GB | 64-bit | For 2GB+ RAM | Ubuntu Base

UI: LXQt 1.4 | Theme: Gamma-Dark Royal | Icons: Papirus-Dark
Installer: Calamares + Ubiquity
Live User: gamma | Password: gamma

 ***3. INSTALLATION GUIDE - 3 STEPS ONLY***

STEP 1: FLASH THE ISO
  Use Ventoy, BalenaEtcher, or Rufus in DD mode.

STEP 2: BOOT & SETUP
 1. Boot the ISO -> Auto-login as 'gamma'
 2. 'Gamma Setup' opens automatically on Desktop
 3. Choose Browser: Falkon, Firefox-ESR, or Chromium
 4. Click 'Install Gamma Linux' icon on Desktop

STEP 3: FIRST BOOT AFTER INSTALL
  Run these in Terminal to apply Royal Theme:
  gamma-theme gamma -> Apply Royal Dark Theme + Icons
  gamma-theme king -> Apply Royal Theme only

 ***4. SYSTEM REQUIREMENTS***

Legacy 32 : 512MB RAM, 4GB Disk, 32-bit or 64-bit CPU
Lite Ghost: 1GB RAM, 6GB Disk, 64-bit CPU
Fatih Pro : 2GB RAM, 8GB Disk, 64-bit CPU

***5. KNOWN BUGS & SOLUTIONS***

**[B1] WIFI NOT SHOWING ON LIVE**
  Fix: sudo apt update && sudo apt install firmware-linux

**[B2] SOUND NOT WORKING AFTER INSTALL**
  Fix: alsamixer -> Unmute with M key -> F6 -> Select Card

**[B3] SCREEN TOO SMALL 800x600 IN VIRTUALBOX**
  Fix: sudo apt install virtualbox-guest-x11 && reboot

**[B4] CALAMARES CRASH AT PARTITION STEP**
  Fix: sudo gparted -> Device -> Create Partition Table -> msdos
       WARNING: This erases all data on disk!

**[B5] GAMMA SETUP DOES NOT OPEN**
  Fix: /usr/local/bin/gamma-setup

**[B6] TOO MUCH SWAP USAGE ON 512MB RAM**
  Fix: Already tuned. Swappiness=10. Close browser tabs if lag.

 **6. CHECKSUMS & VERIFY**

Command: sha256sum -c SHA256SUMS.txt

 **7. CONTACT & COMMUNITY**

**Telegram Group**: https://t.me/GammaLinuxDZ <- Main Support & Chat
**Messenger Group**(recommend)
https://m.me/j/AbahTOn_gqLy8R3k/?send_source=gc%3Acopy_invite_link_t
GitHub: https://github.com/takismartgamer123-rgb/Gamma-linux
See CONTRIBUTE.txt for how to help.

******Made with rage, coffee, and 7-minute CI/CD in Algeria 🇩🇿******
