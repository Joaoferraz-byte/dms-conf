
## 2026-08-31 — Lambda launcher icon stroke

The launcher lambda asset used `stroke-width="4"`, so its visual weight did not match the requested thick icon treatment. The SVG now uses `stroke-width="7"` while preserving its 24×24 viewBox and geometry, and the `noctalia-config` flake check now validates the same value.

## 2026-08-31 — FreeSM launcher argv execution

The provider built the configured launcher command as a shell string, concatenated `--launch <instance>` and redirected stderr. That made dynamic instance ids depend on shell parsing and hid the actual process result; the provider also had no notification path for a failed launch. Prism/Freesm's documented CLI accepts `--launch` as a normal argument.

The provider now tokenizes the configured command into argv, appends `--launch` and the instance id as separate arguments, uses Noctalia's direct argv form of `runAsync`, logs non-zero stderr and notifies the user when execution is rejected or fails. The old shell-string and redirection path is covered by flake checks.


## 2026-08-31 — FreeSM Launcher instance discovery

The provider attempted to read `InstanceDir` from the literal path `.../*.cfg`. Noctalia's `readFile` reads one concrete file and does not expand globs, so the configured FreeSM Launcher Root was silently ignored and discovery always fell back to `<root>/instances`.

The provider now reads the canonical `prismlauncher.cfg` when present, otherwise enumerates only top-level `.cfg`/`.ini` files in deterministic order and selects the one that owns `InstanceDir`. Absolute and relative paths are expanded consistently, the plugin version is `1.0.2`, and the Noctalia flake check rejects a regression to the literal glob. Launch remains direct argv with error reporting.

## Stage 3 — FreeSM-aware launcher instance discovery (2026-09-01)

The `/pl` provider assumed `prismlauncher.cfg` at the configured root, while FreeSM's upstream contract uses `freesmlauncher.cfg` and the same `InstanceDir`/`instance.cfg` layout. This caused a valid FreeSM root to be missed or discovered only through an ambiguous fallback.

The provider now prioritizes `freesmlauncher.cfg`, retains Prism/PolyMC/MultiMC compatibility, considers native and Flatpak FreeSM/Prism roots, resolves relative and absolute `InstanceDir` values, validates the instances directory, sorts results deterministically, caches the selected root for a query, and logs the selected root/configuration. Launching remains an argv-based async call without shell interpolation. The flake contract now checks both FreeSM and Prism names.
