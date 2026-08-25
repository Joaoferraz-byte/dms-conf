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
  };

  outputs = inputs@{ self, nixpkgs, noctalia, official-plugins, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      homeModules.noctalia = { config, lib, pkgs, ... }:
        let
          rawSettings = builtins.readFile (self + "/config/noctalia/config.toml");
          settings = pkgs.writeText "noctalia-config.toml" (lib.replaceStrings
            [ "@NOCTALIA_PALETTE_TEMPLATE@" "@NOCTALIA_NVIM_TEMPLATE@" "@NOCTALIA_FIREFOX_TEMPLATE@" "@NOCTALIA_ZEN_TEMPLATE@" ]
            [ "${self}/config/noctalia/templates/livara-palette.json" "${self}/config/noctalia/templates/nvim-base16.lua" "${self}/config/noctalia/templates/firefox.css" "${self}/config/noctalia/templates/zen-userchrome.css" ]
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
            "noctalia/plugins/screen_recorder".source = official-plugins + "/screen_recorder";
            "noctalia/plugins/timer".source = official-plugins + "/timer";
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
              ${self}/config/noctalia/config.toml > config.toml
            noctalia config validate config.toml
            touch "$out"
          '';
          plugin-manifests = pkgs.runCommand "noctalia-plugin-manifest-check" { } ''
            grep -q '^id[[:space:]]*=[[:space:]]*"dotnetrob/cat"' ${self}/plugins/cat/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/screen_recorder"' ${official-plugins}/screen_recorder/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/timer"' ${official-plugins}/timer/plugin.toml
            grep -q '^plugin_api[[:space:]]*=[[:space:]]*[0-9]' ${self}/plugins/cat/plugin.toml
            test -f ${self}/plugins/cat/cat.luau
            test -f ${official-plugins}/screen_recorder/recorder_service.luau
            test -f ${official-plugins}/timer/service.luau
            touch "$out"
          '';
        });
    };
}
