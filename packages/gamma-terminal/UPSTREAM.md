# Gamma Terminal source integration

## Source of truth

The terminal engine is Sakura 3.8.6, fetched from the upstream tag `SAKURA_3_8_6` in `dabisu/sakura`. The earlier `Gamma-Terminal-1.0.0-src` archive was a separate GTK 3/VTE prototype. Its C implementation is not copied over Sakura's process or tab lifecycle.

## Integrated from the prototype

- Gamma Aurora colour palette and dark UI colour tokens.
- Gamma SVG icon and application identity.
- Header-bar layout and actions, wired to Sakura's native new-tab, search, fullscreen and context-menu callbacks.
- A right-side GTK Controls panel wired to Sakura's native new-tab, copy, paste, tab naming, settings menu, about dialog and close-tab callbacks.
- GTK CSS visual treatment; no EFL, Elementary or Terminology dependency.

## Preserved from Sakura

VTE terminal widget, child process lifecycle, notebook/tab model, URL and mail matching, search, copy/paste, font/colour dialogs and CLI argument handling remain owned by Sakura. Gamma uses its own configuration directory and key-file group so existing Sakura settings are not overwritten.

## Ported and remaining work

The Terminology-inspired split controls are implemented directly in the Sakura GTK/VTE application:

- One horizontal or vertical GTK Paned split per notebook tab, with two independent VTE/PTy child processes.
- Pane focus tracking and pane-aware copy, paste, search, title updates and working-directory inheritance.
- Child-exit handling that collapses the split and preserves the surviving shell.
- Optional grouped input broadcast through VTE's commit signal, including clipboard paste.
- A read-only terminal scrollback snapshot shown by Miniview.

The implementation deliberately limits each tab to two panes for now. Recursive split trees and a live-updating Miniview remain deferred until a dedicated pane-tree model can be added without compromising Sakura's process lifecycle.

## Packaging

The workflow fetches the pinned upstream tag, applies the version-checked patch script and builds `Architecture: any` DEBs in Debian 12 containers for amd64 and i386. An architecture-independent package would be invalid for this compiled executable.
