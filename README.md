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

The repository contains two opt-in patches applied by the package: the Network widget is enabled by `NetworkService.networkAvailable`, allowing Ethernet on hosts without Wi-Fi; and the PowerMenu receives a Game/Normal action conditioned on the `LIVARA_DMS_GAME_MODE` and `LIVARA_DMS_GAMEMODE_CONTROL` variables. The second patch does not alter the three native PowerProfiles and does not appear on the Latitude. Application was tested on the real package: `patchPhase`/Go/check pass, `installPhase` copies QML, applies both patches, and `fixupPhase` completes without error.

The Game button is implemented as a GameMode request maintained by a user service. The backend in `nix-conf` uses `gamemoded -r`, reads state via `systemctl --user is-active`, and releases the request with `SIGINT`; GameMode remains semantically separate from `power-profiles-daemon`.

Nautilus, Fastfetch/Roxy, AudioRelay, Matugen/adapters, and tablet detection remain outside dms-conf. In particular, GIO metadata already fixes the folder icon in Nautilus content view, but the bookmarks sidebar uses symbolic icons per the upstream contract; a bookmark patch should originate in the Nautilus repository, not be hidden inside DMS.
