# Noctalia runtime for Livara

This repository is the local runtime boundary for Noctalia. It tracks the upstream Noctalia flake as an input and re-exports its package and Home Manager module with one deliberate policy change: the systemd user service is disabled by default because Niri owns the single Noctalia process through `spawn-at-startup`.

The repository does not own bar composition, wallpaper policy, templates, plugins, application adapters, or mutable Noctalia settings. Those are integration concerns provided by `shell-conf`, which imports this runtime contract. Keeping the upstream runtime here makes source-level Noctalia changes reviewable without mixing them with the user's desktop policy.

## Contract

| Output | Purpose |
| --- | --- |
| `packages.<system>.default` | Upstream Noctalia package exposed through the local runtime boundary. |
| `overlays.default` | Makes the local package available as `pkgs.noctalia` when an overlay is desired. |
| `homeModules.default` | Imports the upstream Home Manager module and disables its duplicate systemd lifecycle. |
| `homeModules.noctalia` | Compatibility alias for the default module. |

The source input is pinned by `flake.lock`. Any source-level Noctalia modification must be represented by a reviewed upstream revision or a small local patch in this repository; user policy belongs in `shell-conf`.

## Composition

```nix
inputs.noctalia-conf = {
  url = "github:Joaoferraz-byte/noctalia-conf";
  inputs.nixpkgs.follows = "nixpkgs";
};

home-manager.sharedModules = [
  inputs.noctalia-conf.homeModules.default
  inputs.shell-conf.homeModules.support
];
```

Niri remains the compositor owner in `nix-conf`. `shell-conf` owns the curated Noctalia TOML, local plugins, application adapters, and mutable-state policy. The upstream package remains a separate dependency with a stable local contract.

## Validation

Run `nix flake check --no-build --no-update-lock-file --all-systems` in this repository and in `shell-conf`. On a target host, verify the package version, the generated Home Manager option, and that exactly one Noctalia process is started by Niri.

## References

[1]: https://docs.noctalia.dev/noctalia/ "Noctalia v5 documentation"
[2]: https://docs.noctalia.dev/noctalia/compositor-settings/niri/ "Noctalia v5 Niri integration"
[3]: https://github.com/noctalia-dev/noctalia "Upstream Noctalia"
