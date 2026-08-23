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
          #
          # The upstream cp line looks like:
          #   cp -r /nix/store/…-source/quickshell/. $out/share/quickshell/dms/
          # We locate it with a flexible regex that tolerates leading whitespace
          # and arbitrary store-path hashes, then inject a `chmod -R u+w` so the
          # subsequent `patch` invocations can modify the copied QML in place.
          # After patching we verify that the expected marker strings are present
          # in the patched files, failing the build loudly if a patch was silently
          # rejected or the upstream layout changed.
          postInstall =
            let
              original = old.postInstall or "";
              lines = nixpkgs.lib.splitString "\n" original;
              # Match any line that copies the quickshell source dir into the
              # output. Allow leading whitespace and any /nix/store path.
              # builtins.match uses extended POSIX regex with full-string match.
              copyLineRegex = "[[:space:]]*cp[[:space:]]+-r[[:space:]]+/nix/store/[^ ]*/quickshell/\\.[[:space:]].*";
              copyLines = nixpkgs.lib.filter
                (line: builtins.match copyLineRegex line != null)
                lines;
              copyLine = if copyLines == [ ] then
                throw "dms-conf: upstream postInstall no longer contains the expected QML copy line"
              else
                builtins.head copyLines;
              writableCopy = copyLine + "\nchmod -R u+w $out/share/quickshell/dms";
              patchCommands = ''
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0001-livara-network-widget-on-ethernet.patch}"
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0002-livara-game-mode-power-action.patch}"
                # Verify patches landed: each patch introduces a unique marker
                # string that must be present in the installed QML after patching.
                grep -q 'NetworkService\.networkAvailable' "$out/share/quickshell/dms/Modules/ControlCenter/Models/WidgetModel.qml" \
                  || { echo "dms-conf: network-widget patch marker missing in WidgetModel.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_GAME_MODE' "$out/share/quickshell/dms/Modals/PowerMenuModal.qml" \
                  || { echo "dms-conf: game-mode patch marker missing in PowerMenuModal.qml" >&2; exit 1; }
                grep -q 'modelData\.gameMode' "$out/share/quickshell/dms/Modules/Settings/PowerSleepTab.qml" \
                  || { echo "dms-conf: game-mode patch marker missing in PowerSleepTab.qml" >&2; exit 1; }
              '';
            in
            nixpkgs.lib.replaceStrings [ copyLine ] [ writableCopy ] original + patchCommands;
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
            # Verify content-level markers so a silently-rejected patch fails the check.
            grep -q 'NetworkService\.networkAvailable' "$out/Modules/ControlCenter/Models/WidgetModel.qml" \
              || { echo "check: network-widget patch marker missing" >&2; exit 1; }
            grep -q 'LIVARA_DMS_GAME_MODE' "$out/Modals/PowerMenuModal.qml" \
              || { echo "check: game-mode patch marker missing in PowerMenuModal" >&2; exit 1; }
            grep -q 'modelData\.gameMode' "$out/Modules/Settings/PowerSleepTab.qml" \
              || { echo "check: game-mode patch marker missing in PowerSleepTab" >&2; exit 1; }
          '';
        });
    };
}
