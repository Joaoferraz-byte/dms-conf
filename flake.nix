{
  description = "Joaoferraz-byte's reproducible Noctalia v5 integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    official-plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };

    community-templates = {
      url = "github:noctalia-dev/community-templates";
      flake = false;
    };
  };

    outputs = inputs@{ self, nixpkgs, noctalia, official-plugins, ... }:
    let
      communityTemplates = inputs."community-templates";
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      homeModules.noctalia = { config, lib, pkgs, desktopProfile ? {}, ... }:
        let
          screenRecorderPlugin = pkgs.applyPatches {
            name = "noctalia-screen-recorder-focused";
            src = official-plugins + "/screen_recorder";
            patches = [ (self + "/patches/screen-recorder-focused.patch") ];
          };
          # The shared TOML remains valid and readable in the repository. The
          # host-specific bar policy is materialized here from the same
          # desktopProfile contract used by the NixOS host modules.
          batteryOnBar = (desktopProfile.monitorProfile or null) == "latitude";
          barEnd = if batteryOnBar
            then ''end = ["media", "bar", "recorder", "notifications", "battery", "session"]''
            else ''end = ["media", "bar", "recorder", "notifications", "session"]'';
          rawSettings = builtins.readFile (self + "/config/noctalia/config.toml");
          settings = pkgs.writeText "noctalia-config.toml" (lib.replaceStrings
            [ "@NOCTALIA_PALETTE_TEMPLATE@" "@NOCTALIA_NVIM_TEMPLATE@" "@NOCTALIA_FIREFOX_TEMPLATE@" "@NOCTALIA_ZEN_TEMPLATE@" "@NOCTALIA_LAMBDA_ICON@" "@NOCTALIA_DISCORD_TEMPLATE@" "@NOCTALIA_TAUON_TEMPLATE@" "@NOCTALIA_HEROIC_TEMPLATE@" "@NOCTALIA_PRISM_TEMPLATE@" "end = [\"media\", \"bar\", \"recorder\", \"notifications\", \"session\"]" ]
            [ "${self}/config/noctalia/templates/livara-palette.json" "${self}/config/noctalia/templates/nvim-base16.lua" "${self}/config/noctalia/templates/firefox.css" "${self}/config/noctalia/templates/zen-userchrome.css" "${self}/assets/lambda-thick.svg" "${communityTemplates}/discord/discord-material.css" "${communityTemplates}/tauon/tauon.txt" "${communityTemplates}/heroiclauncher/heroic.css" "${communityTemplates}/prismlauncher/prismlauncher.json" barEnd ]
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
            "noctalia/plugins/screen_recorder".source = screenRecorderPlugin;
            "noctalia/plugins/timer".source = official-plugins + "/timer";
          };

          # Explicit, backup-first repair for GUI state left by the retired
          # second bar. It is installed but never run automatically.
          home.file.".local/bin/repair-noctalia-stale-bars".source = self + "/scripts/repair-noctalia-stale-bars.sh";
          home.file.".local/bin/ensure-noctalia-recorder-bar".source = self + "/scripts/ensure-noctalia-recorder-bar.sh";
        };

      homeModules.default = self.homeModules.noctalia;

      checks = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          screenRecorderPlugin = pkgs.applyPatches {
            name = "noctalia-screen-recorder-focused";
            src = official-plugins + "/screen_recorder";
            patches = [ (self + "/patches/screen-recorder-focused.patch") ];
          };
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
              -e 's|@NOCTALIA_TAUON_TEMPLATE@|${communityTemplates}/tauon/tauon.txt|g' \
              -e 's|@NOCTALIA_HEROIC_TEMPLATE@|${communityTemplates}/heroiclauncher/heroic.css|g' \
              -e 's|@NOCTALIA_PRISM_TEMPLATE@|${communityTemplates}/prismlauncher/prismlauncher.json|g' \
              ${self}/config/noctalia/config.toml > config.toml
            noctalia config validate config.toml
            touch "$out"
          '';
          plugin-manifests = pkgs.runCommand "noctalia-plugin-manifest-check" { } ''
            grep -q '^id[[:space:]]*=[[:space:]]*"dotnetrob/cat"' ${self}/plugins/cat/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/screen_recorder"' ${screenRecorderPlugin}/plugin.toml
            grep -q '^default[[:space:]]*=[[:space:]]*"focused"' ${screenRecorderPlugin}/plugin.toml
            grep -q 'fallback-cpu-encoding yes' ${screenRecorderPlugin}/recorder_service.luau
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/timer"' ${official-plugins}/timer/plugin.toml
            grep -q '^plugin_api[[:space:]]*=[[:space:]]*[0-9]' ${self}/plugins/cat/plugin.toml
            test -f ${self}/plugins/cat/cat.luau
            test -f ${self}/plugins/cat/cat_panel.luau
            test -f ${self}/plugins/cat/fonts/catwalk2.otf
            grep -q 'fontFamily = catFont' ${self}/plugins/cat/cat_panel.luau
            test -f ${self}/scripts/repair-noctalia-stale-bars.sh
            test -f ${self}/scripts/ensure-noctalia-recorder-bar.sh
            test -f ${screenRecorderPlugin}/recorder_service.luau
            test -f ${official-plugins}/timer/service.luau
            touch "$out"
          '';
        });
    };
}
