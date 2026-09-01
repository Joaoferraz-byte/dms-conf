
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

## Stage 5 — User icon for the control-center widget (2026-09-01)

The control-center widget used the thick Lambda SVG even though the session avatar was already configured through `.face`, `.face.icon` and the Noctalia `avatar_path`. The task concerned the launcher/control-center icon, so changing only the AccountsService avatar would not affect the visible widget.

A dedicated 512×512 RGB PNG is now derived from the same user profile image with a centered square crop that preserves proportions. The widget uses the prepared asset, disables colorization so the portrait is not flattened into the accent color, and switches its glyph metadata to `user`. The flake now checks the asset and placeholder wiring; the system avatar files remain owned by nix-conf.

## Stage 2 — Japanese Kanji control-center icon (2026-09-01)

The visible bar button is `widget.control-center`, not the disabled-by-default standalone dock launcher. The prior lambda/user-image wiring therefore changed the control-center button while leaving the supplied launcher asset contract ambiguous; adding a separate `[widget.launcher]` would create a second button and change the bar geometry.

The button now loads the supplied Japanese Kanji SVG through a dedicated `@NOCTALIA_CONTROL_CENTER_ICON@` asset placeholder. Noctalia renders it with `Contain`, preserving the square viewBox and proportions, while `custom_image_colorize = true` applies the active widget/theme color to the alpha mask for adaptive light/dark output. The `user` glyph remains only as fallback metadata. Static checks parse the TOML, parse the SVG, verify the viewBox and require the active placeholder wiring.

## Stage 3 — Retire unused icon wiring (2026-09-01)

After the Japanese Kanji asset became the active control-center image, the former lambda SVG, user portrait PNG and their flake substitution/checks had no runtime consumer. Keeping them made the asset graph claim two obsolete owners and contradicted the current configuration.

The unused assets and lambda placeholder path were removed from the flake. Historical changelog entries remain intact so the migration path is auditable, while the active flake now validates only the Japanese Kanji asset and the other live templates.

## 2026-09-01 — Restore vector launcher mark

The active shell integration had retired the historical `lambda-thick.svg` launcher asset in favor of the Japanese Kanji control-center mark. The user-visible result no longer matched the previously approved launcher artwork and could fall back to a textual lambda glyph.

The Noctalia `widget.control-center` now consumes the restored vector `assets/lambda-thick.svg`, keeps adaptive colorization, and retains `glyph = "lambda"` only as the fallback identifier. The flake substitutes and validates the same asset, viewBox and stroke width in both its generated settings path and static check. The current shell owner is Noctalia v5; no QuickShell runtime was reintroduced.
