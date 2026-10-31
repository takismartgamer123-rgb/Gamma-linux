# Gamma Terminal source integration

## Source of truth

The terminal engine is Sakura 3.8.6, fetched from the upstream tag `SAKURA_3_8_6` in `dabisu/sakura`. The earlier `Gamma-Terminal-1.0.0-src` archive was a separate GTK 3/VTE prototype. Its C implementation is not copied over Sakura's process or tab lifecycle.

## Integrated from the prototype

- Gamma Aurora colour palette and dark UI colour tokens.
- Gamma SVG icon and application identity.
- Header-bar layout and actions, wired to Sakura's native new-tab, search, fullscreen and context-menu callbacks.
- GTK CSS visual treatment; no EFL, Elementary or Terminology dependency.

## Preserved from Sakura

VTE terminal widget, child process lifecycle, notebook/tab model, URL and mail matching, search, copy/paste, font/colour dialogs and CLI argument handling remain owned by Sakura. Gamma uses its own configuration directory and key-file group so existing Sakura settings are not overwritten.

## Deferred

The prototype's split-pane UI is documented but intentionally not ported in this first integration. Sakura binds process state and exit handling to each notebook tab; split panes require a correct multi-terminal container and per-pane lifecycle. A superficial widget addition would risk child-process cleanup and session behavior.

## Packaging

The workflow fetches the pinned upstream tag, applies the version-checked patch script and builds `Architecture: any` DEBs in Debian 12 containers for amd64 and i386. An architecture-independent package would be invalid for this compiled executable.
