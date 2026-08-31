{
  description = "Joaoferraz-byte's reproducible Noctalia v5 integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    community-templates = {
      url = "github:noctalia-dev/community-templates";
      flake = false;
    };
  };

    outputs = inputs@{ self, nixpkgs, noctalia, ... }:
    let
      communityTemplates = inputs."community-templates";
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      homeModules.noctalia = { config, lib, pkgs, desktopProfile ? {}, ... }:
        let
          # The shared TOML remains valid and readable in the repository. The
          # host-specific bar policy is materialized here from the same
          # desktopProfile contract used by the NixOS host modules.
          batteryOnBar = (desktopProfile.monitorProfile or null) == "latitude";
          barEnd = if batteryOnBar
            then ''end = ["media", "bar", "recorder", "notifications", "battery", "session"]''
            else ''end = ["media", "bar", "recorder", "notifications", "session"]'';
          rawSettings = builtins.readFile (self + "/config/noctalia/config.toml");
          settings = pkgs.writeText "noctalia-config.toml" (lib.replaceStrings
            [ "@NOCTALIA_PALETTE_TEMPLATE@" "@NOCTALIA_NVIM_TEMPLATE@" "@NOCTALIA_FIREFOX_TEMPLATE@" "@NOCTALIA_ZEN_TEMPLATE@" "@NOCTALIA_LAMBDA_ICON@" "@NOCTALIA_DISCORD_TEMPLATE@" "@NOCTALIA_HEROIC_TEMPLATE@" "@NOCTALIA_PRISM_TEMPLATE@" "end = [\"media\", \"bar\", \"recorder\", \"notifications\", \"session\"]" ]
            [ "${self}/config/noctalia/templates/livara-palette.json" "${self}/config/noctalia/templates/nvim-base16.lua" "${self}/config/noctalia/templates/firefox.css" "${self}/config/noctalia/templates/zen-userchrome.css" "${self}/assets/lambda-thick.svg" "${communityTemplates}/discord/discord-material.css" "${communityTemplates}/heroiclauncher/heroic.css" "${communityTemplates}/prismlauncher/prismlauncher.json" barEnd ]
            rawSettings);
        in
        {
          imports = [ noctalia.homeModules.default ];

          programs.noctalia = {
            enable = true;
            # Niri starts Noctalia once through spawn-at-startup. Enabling the
            # upstream service as well would create two shell processes.
            systemd.enable = false;
            checkConfig = true;
            inherit settings;
          };

          # Local plugins are reviewed and pinned by this flake. Home Manager
          # creates store-backed symlinks; mutable plugin state stays outside
          # the repository under XDG_STATE_HOME/noctalia.
          xdg.dataFile = {
            "noctalia/plugins/cat".source = self + "/plugins/cat";
            "noctalia/plugins/screen_recorder".source = self + "/plugins/screen_recorder";
            "noctalia/plugins/timer".source = self + "/plugins/timer";
            "noctalia/plugins/screen_toolkit".source = self + "/plugins/screen_toolkit";
            "noctalia/plugins/gamer_mode".source = self + "/plugins/gamer_mode";
            "noctalia/plugins/dns_switcher".source = self + "/plugins/dns_switcher";
            "noctalia/plugins/prismlauncher_instances".source = self + "/plugins/prismlauncher_instances";
            "noctalia/plugins/bitwarden".source = self + "/plugins/bitwarden";
          };

        };

      homeModules.default = self.homeModules.noctalia;

      checks = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          noctalia-config = pkgs.runCommand "noctalia-config-check" {
            nativeBuildInputs = [ noctalia.packages.${system}.default ];
          } ''
            sed \
              -e 's|@NOCTALIA_PALETTE_TEMPLATE@|${self}/config/noctalia/templates/livara-palette.json|g' \
              -e 's|@NOCTALIA_NVIM_TEMPLATE@|${self}/config/noctalia/templates/nvim-base16.lua|g' \
              -e 's|@NOCTALIA_FIREFOX_TEMPLATE@|${self}/config/noctalia/templates/firefox.css|g' \
              -e 's|@NOCTALIA_ZEN_TEMPLATE@|${self}/config/noctalia/templates/zen-userchrome.css|g' \
              -e 's|@NOCTALIA_LAMBDA_ICON@|${self}/assets/lambda-thick.svg|g' \
              -e 's|@NOCTALIA_DISCORD_TEMPLATE@|${communityTemplates}/discord/discord-material.css|g' \
              -e 's|@NOCTALIA_HEROIC_TEMPLATE@|${communityTemplates}/heroiclauncher/heroic.css|g' \
              -e 's|@NOCTALIA_PRISM_TEMPLATE@|${communityTemplates}/prismlauncher/prismlauncher.json|g' \
              ${self}/config/noctalia/config.toml > config.toml
            noctalia config validate config.toml
            grep -q 'stroke-width="7"' ${self}/assets/lambda-thick.svg
            grep -q 'viewBox="0 0 24 24"' ${self}/assets/lambda-thick.svg
            touch "$out"
          '';
          plugin-manifests = pkgs.runCommand "noctalia-plugin-manifest-check" { } ''
            grep -q '^id[[:space:]]*=[[:space:]]*"dotnetrob/cat"' ${self}/plugins/cat/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/screen_recorder"' ${self}/plugins/screen_recorder/plugin.toml
            grep -q '^default[[:space:]]*=[[:space:]]*"focused"' ${self}/plugins/screen_recorder/plugin.toml
            grep -q 'fallback-cpu-encoding yes' ${self}/plugins/screen_recorder/recorder_service.luau
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/timer"' ${self}/plugins/timer/plugin.toml
            grep -q '^plugin_api[[:space:]]*=[[:space:]]*[0-9]' ${self}/plugins/cat/plugin.toml
            test -f ${self}/plugins/cat/cat.luau
            test -f ${self}/plugins/cat/cat_panel.luau
            test -f ${self}/plugins/cat/fonts/catwalk2.otf
            grep -q 'fontFamily = catFont' ${self}/plugins/cat/cat_panel.luau
            test -f ${self}/plugins/screen_recorder/recorder_service.luau
            test -f ${self}/plugins/timer/service.luau
            grep -q '^id[[:space:]]*=[[:space:]]*"alexander/screen-toolkit"' ${self}/plugins/screen_toolkit/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"nomadcxx/gamer-mode"' ${self}/plugins/gamer_mode/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"nightwatch75/dns-switcher"' ${self}/plugins/dns_switcher/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"radimous/prismlauncher-instances"' ${self}/plugins/prismlauncher_instances/plugin.toml
            grep -q 'local function splitCommand' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'runAsync(argv, function(result)' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'result.exitCode' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            ! grep -q 'string.format(launcherCommand' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/bitwarden"' ${self}/plugins/bitwarden/plugin.toml
            touch "$out"
          '';
        });
    };
}
