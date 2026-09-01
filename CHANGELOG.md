
## 2026-09-01 — FreeSM root and instance icon audit

The supplied FreeSM instance archive confirmed the active root as `~/.var/app/org.freesmlauncher.FreesmLauncher/data/FreesmLauncher/instances`, containing valid OneSix instances with `instance.cfg` and `mmc-pack.json`. The configured default had incorrectly named the parent directory `PrismLauncher`; the configuration, plugin setting and documentation now use the actual `FreesmLauncher` root.

The provider's icon lookup also called the nonexistent `getPrismPath()` function. It now resolves the icon directory from the same launcher root selected by instance discovery, preserving fallback behavior to `minecraft/icon.png` when a keyed launcher icon cannot be found.

Books, Games and Musics now share one consistent Kora-like full-colour folder silhouette and palette in the main folder view. Their sidebar assets remain a separate symbolic contract; in particular, Games now uses a recognizable gamepad glyph rather than a generic folder/plus icon.

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

## 2026-09-01 — Keep the Japanese Kanji launcher mark

The previous follow-up incorrectly reintroduced the retired lambda launcher asset. The selected design is the Japanese Kanji SVG, so the Noctalia `widget.control-center` again consumes `assets/japanese-kanji.svg`, with adaptive colorization and the existing user glyph as fallback. The flake substitution and static check now point only to the Kanji asset and its `viewBox="0 0 38.427 38.427"`. No lambda asset or glyph is active, and no QuickShell runtime was reintroduced.
