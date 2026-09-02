# Gamer Mode

Noctalia v5 plugin for live CPU, RAM and GPU readings plus a toggle that suspends configured resource-heavy targets and restores them afterward.

## Contract

| Field | Value |
|---|---|
| ID | `nomadcxx/gamer-mode` |
| Entries | `gamermode` and `monitor` widgets, `main` panel, `service` IPC |
| Runtime | Noctalia v5, plugin API 19 |

## Dependencies

Install only the binaries required by the features enabled in the plugin settings:

| Binary | Role |
|---|---|
| `pgrep`, `pkill` | Probe and signal process targets |
| `systemctl` | Control service and timer targets |
| `docker` | Control container targets |
| `powerprofilesctl` | Select power profiles |

Missing optional binaries hide only the related feature; the main toggle remains available.

## Usage

Add `gamermode` for a compact toggle or `monitor` for live readings. Left-click opens the panel by default; right-click toggles the mode. The panel supports `light` and `heavy` profiles and exposes the configured maintenance actions.

```sh
noctalia msg plugin nomadcxx/gamer-mode:service all toggle
noctalia msg plugin nomadcxx/gamer-mode:service all enable
noctalia msg plugin nomadcxx/gamer-mode:service all disable
noctalia msg panel-toggle nomadcxx/gamer-mode:main
```

The profile is selected when gamer mode is enabled and cannot be changed while the session is active. Disable the mode before selecting another profile.

## Widget configuration

```toml
[widget.gamermonitor]
type = "nomadcxx/gamer-mode:monitor"
capsule = true
```

The monitor can join an existing capsule group. Its settings control metric visibility, reserved value width, warning thresholds and the optional flame indicator. The widget does not create a second bar background.

## Maintenance actions

The panel can expose one-shot actions for shader-cache cleanup, page-cache dropping and swap reclamation. The latter two require authentication and are independent of the gamer-mode toggle.

## Settings

All settings are available under **Settings → Plugins**. The main groups are:

| Group | Examples |
|---|---|
| Metrics | CPU/RAM/GPU usage and temperature, VRAM, swap, load average, network rates |
| Profiles | `light` and `heavy` target sets |
| Visuals | Icons, reserved value width, flame mode and highlight behavior |
| Maintenance | Shader-cache cleanup, page-cache dropping and swap reclamation |

See the plugin settings schema in `plugin.toml` for the complete option list and defaults. This README documents the public contract rather than duplicating that schema.

## Validation

Verify plugin discovery, widget rendering, IPC toggle/enable/disable, missing-dependency behavior and restoration of suspended targets. Run the repository's Noctalia checks before enabling the plugin in the system configuration.
