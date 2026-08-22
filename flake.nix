{
  description = "Livara's reproducible first-layer patches for DankMaterialShell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    dms = {
      url = "github:AvengeMedia/DankMaterialShell?rev=069ddab041c738236a8910e4c39b65d9628d3018";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dms }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      mkPackage = system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        (dms.lib.mkDmsShell pkgs).overrideAttrs (old: {
          pname = "dms-shell-livara";
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.patch ];
          # mkDmsShell intentionally builds the Go core from a reduced `core`
          # source archive and copies QML from the full immutable DMS source in
          # postInstall. Make that copy writable before patching it in-place.
          postInstall =
            let
              original = old.postInstall or "";
              copyLines = nixpkgs.lib.filter
                (line: builtins.match "cp -r /nix/store/.*-source/quickshell/\\..*" line != null)
                (nixpkgs.lib.splitString "\n" original);
              copyLine = if copyLines == [ ] then
                throw "dms-conf: upstream postInstall no longer contains the expected QML copy"
              else
                builtins.head copyLines;
              writableCopy = copyLine + "\nchmod -R u+w $out/share/quickshell/dms";
            in
            nixpkgs.lib.replaceStrings [ copyLine ] [ writableCopy ] original + ''
              patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0001-livara-network-widget-on-ethernet.patch}"
              patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0002-livara-game-mode-power-action.patch}"
            '';
        });
    in
    {
      packages = nixpkgs.lib.genAttrs systems (system: {
        default = mkPackage system;
        dms-shell-livara = mkPackage system;
      });

      homeModules.dank-material-shell = { lib, pkgs, ... }:
        {
          imports = [ dms.homeModules.dank-material-shell ];
          config.programs.dank-material-shell.package = lib.mkForce self.packages.${pkgs.system}.default;
        };

      homeModules.default = self.homeModules.dank-material-shell;

      checks = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          patches-apply = pkgs.runCommand "dms-conf-patches-apply" {
            nativeBuildInputs = [ pkgs.patch ];
          } ''
            cp -r ${dms}/quickshell/. "$out/"
            chmod -R u+w "$out"
            patch -p2 -d "$out" < "${./patches/0001-livara-network-widget-on-ethernet.patch}"
            patch -p2 -d "$out" < "${./patches/0002-livara-game-mode-power-action.patch}"
            test -s "$out/Modules/ControlCenter/Models/WidgetModel.qml"
            test -s "$out/Modals/PowerMenuModal.qml"
            test -s "$out/Modules/Settings/PowerSleepTab.qml"
          '';
        });
    };
}
