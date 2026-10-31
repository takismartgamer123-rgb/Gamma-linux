# Gamma Terminal 1.0.0

**Sakura-powered. Terminology-inspired. Gamma-designed.**

Gamma Terminal is a Gamma Linux fork of [Sakura](https://github.com/dabisu/sakura), pinned to upstream tag `SAKURA_3_8_6`. It keeps Sakura's GTK 3 + VTE terminal engine and existing terminal/session implementation. The earlier standalone Gamma Terminal prototype is used as a design reference, not as a second terminal engine.

## What this fork changes

- Gamma Aurora GTK styling for the window, header bar, menus, notebook tabs and scrollbars.
- Gamma Aurora 16-colour terminal palette and matching dark default scheme.
- Gamma-branded header-bar actions for new tab, search, fullscreen and the existing Sakura context menu.
- Separate application identity: `gamma-terminal` executable, desktop entry, icon, gettext domain, manual page and configuration namespace.
- Separate per-user settings at `~/.config/gamma-terminal/gamma-terminal.conf`.

## What remains from Sakura

Sakura continues to own terminal emulation through VTE, PTY/process lifecycle, tab management, URL/mail matching, search, copy/paste, font and colour settings, and command-line options. No Terminology or EFL runtime dependencies are introduced.

## Build dependencies (Debian 12 / Bookworm)

```bash
sudo apt update
sudo apt install build-essential cmake pkg-config perl gettext \
  libglib2.0-dev libgtk-3-dev libvte-2.91-dev libx11-dev libpcre2-dev
```

Build from the patched source:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build --parallel
```

The executable is `build/src/gamma-terminal`.

## Debian packages

The source package declares `Architecture: any`, producing an architecture-specific binary package. `Architecture: all` would be incorrect because the package contains a compiled native ELF executable. GitHub Actions builds separate `amd64` and `i386` packages in Debian 12 containers. Runtime dependencies are populated from ELF linkage by Debian packaging helpers.

## Deliberately deferred

The earlier standalone prototype contains a split-pane implementation. It is not claimed as part of this Sakura-based release: Sakura associates a VTE child process and lifecycle with each notebook tab, so split panes must be integrated into that model to preserve child-exit handling, working directories, close behavior and focus. The feature needs a dedicated follow-up rather than a fragile second terminal widget.

## Licensing

The Sakura source retains its original GPL-2 copyright and license notices. Gamma modifications and the standalone prototype's Gamma-authored assets are distributed under GPL-compatible terms. See `debian/copyright`.
