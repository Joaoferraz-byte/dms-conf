# dms-conf

`dms-conf` is the optional first-layer patch maintenance layer for **DankMaterialShell** used by the Livara desktop. It does not replace the declarative configuration in `nix-conf` nor the plugins and adapters of `shell-conf`.

## Architectural contract

The separation of responsibilities is deliberate:

| Layer | Responsibility | Typical change |
| --- | --- | --- |
| `nix-conf` | host, hardware, services, capabilities, and system composition | `dmsSettings`, per-capability widgets, units, and locks |
| `shell-conf` | Livara visual API, plugins, adapters, and host-independent files | QML plugin, theme sync, Fastfetch |
| `dms-conf` | small, versioned patches to upstream DMS code | only behavior or geometry the public API does not expose |
| upstream DMS | templates, services, and native components | source of truth; do not edit `/nix/store` |

## Pin and patch policy

Each patch must be applied on an immutable upstream commit, preferably the commit already pinned by the desktop (`069ddab041c738236a8910e4c39b65d9628d3018`). Version updates must be a separate change, accompanied by a fresh audit of QML contracts, settings names, and the plugin interface.

The package is derived from `dms.lib.mkDmsShell`. At the pinned commit, upstream compiles Go from the `core` source root and, in `installPhase`, copies QML from the immutable source. dms-conf preserves this copy, makes only the copy in `$out/share/quickshell/dms` writable, and applies patches to that copy within the same `installPhase`; this avoids trying to write to the `/nix/store` source, which caused the observed failure. The dms-conf `homeModule` imports the official module and forces `programs.dank-material-shell.package` to the patched derivation. No DMS file is edited in `/nix/store` and the upstream clone remains only as a comparison source.

Patches must be small, justified, and indicate the affected upstream file. Do not copy the entire DMS into `shell-conf`, duplicate native templates, or edit files materialized in `/nix/store`.

## Nix integration

Composition in `nix-conf` is explicit: `dmsPackage = inputs.dms-conf.packages.${pkgs.system}.default` and `inputs.dms-conf.homeModules.dank-material-shell` replaces the upstream module in `sharedModules`. The `flake.lock` records the `dms-conf` commit; the internal `dms` input follows the system's already-pinned DMS input, avoiding a second revision.

Integration includes the `patches-apply` check, which copies only the pinned DMS QML tree and confirms that patches apply without rejections. Full desktop builds are left to the host or CI; local validation remains Nix parsing, `git diff --check`, structural patch application, and QML inspection.

## Criteria for promoting a change to a patch

A change belongs in `dms-conf` only if the need is demonstrably first-layer, there is no compatible public setting or plugin, and it can be isolated without assuming host hardware. Likely examples are fixed `WorkspaceSwitcher` geometry and video wallpaper support, but both require proof of need and a complete implementation; GIF or MP4 should not be advertised as supported merely by changing name filters.

Palette changes, application adapters, launcher, fastfetch, AudioRelay, Nautilus, and tablet detection remain outside this layer. They belong respectively to DMS/shell-conf, adapters, nix-conf, or the feature-specific repositories.

## Current state

The repository applies the following patches to the pinned DMS QML tree:

- **0001 network-widget-on-ethernet** — the Network control-center widget is enabled by `NetworkService.networkAvailable`, allowing Ethernet on hosts without Wi-Fi.
- **0002 game-mode-power-action** — the PowerMenu receives a Game/Normal action conditioned on the `LIVARA_DMS_GAME_MODE` and `LIVARA_DMS_GAMEMODE_CONTROL` variables. This does not alter the three native PowerProfiles and does not appear on the Latitude. The Game button is implemented as a GameMode request maintained by a user service; the backend in `nix-conf` uses `gamemoded -r`, reads state via `systemctl --user is-active`, and releases the request with `SIGINT`. GameMode remains semantically separate from `power-profiles-daemon`.
- **0003 remove-weather-sky-graph** — removes the sky-graph canvas from the DankDash weather tab, leaving the compact condition display.
- **0004 power-button-fallback** — adds a fallback power button to the ControlCenter when the canonical power action is unavailable.
- **0006 bar-icon-hidpi-quality** — improves icon rendering quality on HiDPI displays for the RunningApps bar widget.
- **0007 hide-calendar-when-no-backend** — hides the DankDash calendar widget when no calendar backend is configured.
- **0008 tabler-bar-icons** — replaces the Material Symbols Rounded renderer in `Widgets/DankIcon.qml` with a Tabler Icons renderer matching the Noctara-Dots / Noctalia v5 design language. The component preserves the upstream API (`name`, `size`, `color`, `filled`, `fill`, `grade`, `weight`, `smoothTransform`, `rotationCompleted`) so every existing call-site works unchanged; an internal lookup table translates each Material Symbols ligature name to the corresponding Tabler Icons Unicode codepoint. The Tabler Icons TTF (`tabler-icons.ttf` v3.34.0) is bundled in `assets/fonts/tabler-icons/` and installed alongside the DMS QML. Unmapped names fall back to a help glyph so missing mappings are visually obvious. Only bar widget icons are affected; the application icon theme (Kora) and the DankDash weather-tab nerdfont icons (DankNFIcon) are untouched.
- **0009 kora-icon-flicker-fix** — eliminates the visible "default hicolor icon then Kora icon" change that occurred when scrolling the DankLauncherV2 result list. The root cause is that `IconThemeService.resolve()` resolves themed icon paths asynchronously via `find`; while a name is still being looked up, `Paths.themedIconPath()` fell back to `Quickshell.iconPath()` (the hicolor default), which was then replaced by the Kora path once the async `find` completed. The patch adds two mechanisms: (1) `IconThemeService.isResolving(name)` lets `themedIconPath` return an empty string (triggering the neutral letter-avatar fallback) instead of the hicolor default while resolution is pending, and (2) `IconThemeService.preWarm(names)` batch-resolves all application icon names in a single `find` invocation, called from `AppSearchService.refreshApplications()` so the cache is populated before the launcher renders. A `revision`-watched `Connections` block re-prewarms when the icon theme's search-directory chain is first built, covering the startup race where `IconThemeService._rebuild()` completes after `AppSearchService` has already initialised.
- **0010 bar-icon-hd-source-size** — fixes low-resolution (blurry) application icons in all DankBar widgets that use `IconImage` directly rather than the shared `AppIconRenderer` component. The root cause is in QuickShell's `IconImage.qml`: its internal `Image` (exposed via the `backer` property alias) sets `sourceSize.width` and `sourceSize.height` to `root.actualSize` (= `Math.min(width, height)`) by default, which means SVG-based themed icons are rasterised at the display size (e.g. 18×18 px) and look soft on HiDPI screens. The shared `AppIconRenderer` already works around this by overriding `backer.sourceSize: Qt.size(iconSize * 2, iconSize * 2)`, but 17 `IconImage` blocks across 7 bar widget files were missing the override. This patch adds `backer.sourceSize: Qt.size(<displaySize> * 2, <displaySize> * 2)` to every such block, matching the proven 2× approach from `AppIconRenderer`. Files patched: `FocusedApp.qml` (2 blocks), `FocusedWindowContextMenu.qml` (1), `AppsDockContextMenu.qml` (1), `RunningApps.qml` (2), `AppsDock.qml` (1), `SystemTrayBar.qml` (4), `WorkspaceSwitcher.qml` (6).

Each patch introduces a unique `LIVARA_DMS_*` marker string that is verified after application; a missing marker fails the build. The `patches-apply` check applies all patches to a copy of the pinned QML tree and verifies every marker.

Nautilus, Fastfetch/Roxy, AudioRelay, Matugen/adapters, and tablet detection remain outside dms-conf. In particular, GIO metadata already fixes the folder icon in Nautilus content view, but the bookmarks sidebar uses symbolic icons per the upstream contract; a bookmark patch should originate in the Nautilus repository, not be hidden inside DMS.
