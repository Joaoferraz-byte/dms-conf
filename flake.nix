{
  description = "Customized Noctalia desktop shell for Livara";

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
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
      configDirectory = "${self}/config/noctalia";
      pluginDirectory = "${self}/plugins";
      controlCenterIcon = "${self}/assets/japanese-kanji.svg";
      communityTemplates = inputs."community-templates";
      mkSettings = { pkgs, desktopProfile ? { } }:
        let
          batteryOnBar = (desktopProfile.monitorProfile or null) == "latitude";
          barEnd = if batteryOnBar
            then ''end = ["media", "bar", "recorder", "notifications", "battery", "session"]''
            else ''end = ["media", "bar", "recorder", "notifications", "session"]'';
        in
        pkgs.writeText "noctalia-config.toml" (builtins.replaceStrings
          [
            "@NOCTALIA_PALETTE_TEMPLATE@"
            "@NOCTALIA_NVIM_TEMPLATE@"
            "@NOCTALIA_FIREFOX_TEMPLATE@"
            "@NOCTALIA_ZEN_TEMPLATE@"
            "@NOCTALIA_CONTROL_CENTER_ICON@"
            "@NOCTALIA_DISCORD_TEMPLATE@"
            "@NOCTALIA_HEROIC_TEMPLATE@"
            "@NOCTALIA_PRISM_TEMPLATE@"
            "@NOCTALIA_NIRI_TEMPLATE@"
            "end = [\"media\", \"bar\", \"recorder\", \"notifications\", \"session\"]"
          ]
          [
            "${configDirectory}/templates/livara-palette.json"
            "${configDirectory}/templates/nvim-base16.lua"
            "${configDirectory}/templates/firefox.css"
            "${configDirectory}/templates/zen-userchrome.css"
            controlCenterIcon
            "${communityTemplates}/discord/discord-material.css"
            "${communityTemplates}/heroiclauncher/heroic.css"
            "${communityTemplates}/prismlauncher/prismlauncher.json"
            "${configDirectory}/templates/niri.kdl"
            barEnd
          ]
          (builtins.readFile (configDirectory + "/config.toml")));
      mkHomeModule = { lib, pkgs, desktopProfile ? { }, ... }:
        {
          imports = [ noctalia.homeModules.default ];
          programs.noctalia = {
            enable = true;
            systemd.enable = lib.mkForce false;
            checkConfig = true;
            settings = mkSettings { inherit pkgs desktopProfile; };
          };
          xdg.dataFile = {
            "noctalia/plugins/cat".source = pluginDirectory + "/cat";
            "noctalia/plugins/screen_recorder".source = pluginDirectory + "/screen_recorder";
            "noctalia/plugins/timer".source = pluginDirectory + "/timer";
            "noctalia/plugins/screen_toolkit".source = pluginDirectory + "/screen_toolkit";
            "noctalia/plugins/gamer_mode".source = pluginDirectory + "/gamer_mode";
            "noctalia/plugins/prismlauncher_instances".source = pluginDirectory + "/prismlauncher_instances";
            "noctalia/plugins/bitwarden".source = pluginDirectory + "/bitwarden";
          };
        };
    in {
      packages = forEachSystem (system: {
        default = noctalia.packages.${system}.default;
      });

      overlays.default = final: prev: {
        noctalia = noctalia.packages.${final.stdenv.hostPlatform.system}.default;
      };

      homeModules.default = mkHomeModule;
      homeModules.noctalia = mkHomeModule;

      checks = forEachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          noctaliaPackage = noctalia.packages.${system}.default;
        in {
          noctalia-config = pkgs.runCommand "livara-noctalia-config-check" {
            nativeBuildInputs = [ noctaliaPackage ];
          } ''
            sed \
              -e 's|@NOCTALIA_PALETTE_TEMPLATE@|${configDirectory}/templates/livara-palette.json|g' \
              -e 's|@NOCTALIA_NVIM_TEMPLATE@|${configDirectory}/templates/nvim-base16.lua|g' \
              -e 's|@NOCTALIA_FIREFOX_TEMPLATE@|${configDirectory}/templates/firefox.css|g' \
              -e 's|@NOCTALIA_ZEN_TEMPLATE@|${configDirectory}/templates/zen-userchrome.css|g' \
              -e 's|@NOCTALIA_CONTROL_CENTER_ICON@|${controlCenterIcon}|g' \
              -e 's|@NOCTALIA_DISCORD_TEMPLATE@|${communityTemplates}/discord/discord-material.css|g' \
              -e 's|@NOCTALIA_HEROIC_TEMPLATE@|${communityTemplates}/heroiclauncher/heroic.css|g' \
              -e 's|@NOCTALIA_PRISM_TEMPLATE@|${communityTemplates}/prismlauncher/prismlauncher.json|g' \
              -e 's|@NOCTALIA_NIRI_TEMPLATE@|${configDirectory}/templates/niri.kdl|g' \
              ${configDirectory}/config.toml > config.toml
            noctalia config validate config.toml
            test -f ${controlCenterIcon}
            grep -q 'custom_image = "@NOCTALIA_CONTROL_CENTER_ICON@"' ${configDirectory}/config.toml
            grep -q 'custom_image_colorize = true' ${configDirectory}/config.toml
            touch "$out"
          '';
          plugin-manifests = pkgs.runCommand "livara-noctalia-plugin-manifest-check" { } ''
            grep -q '^id[[:space:]]*=[[:space:]]*"dotnetrob/cat"' ${pluginDirectory}/cat/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/screen_recorder"' ${pluginDirectory}/screen_recorder/plugin.toml
            grep -q '^default[[:space:]]*=[[:space:]]*"focused"' ${pluginDirectory}/screen_recorder/plugin.toml
            grep -q 'fallback-cpu-encoding yes' ${pluginDirectory}/screen_recorder/recorder_service.luau
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/timer"' ${pluginDirectory}/timer/plugin.toml
            grep -q '^plugin_api[[:space:]]*=[[:space:]]*[0-9]' ${pluginDirectory}/cat/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"alexander/screen-toolkit"' ${pluginDirectory}/screen_toolkit/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"nomadcxx/gamer-mode"' ${pluginDirectory}/gamer_mode/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"radimous/prismlauncher-instances"' ${pluginDirectory}/prismlauncher_instances/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/bitwarden"' ${pluginDirectory}/bitwarden/plugin.toml
            touch "$out"
          '';
        });
    };
}
