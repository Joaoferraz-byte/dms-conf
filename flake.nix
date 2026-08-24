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
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0003-livara-remove-weather-sky-graph.patch}"
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0004-livara-power-button-fallback.patch}"
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0006-livara-bar-icon-hidpi-quality.patch}"
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0007-livara-hide-calendar-when-no-backend.patch}"
                # Install the bundled Tabler Icons font so the patched DankIcon
                # (which loads it via FontLoader + Qt.resolvedUrl) can resolve
                # the TTF at runtime. The path ../assets/fonts/tabler-icons/
                # is relative to Widgets/DankIcon.qml in the installed tree.
                mkdir -p "$out/share/quickshell/dms/assets/fonts/tabler-icons"
                cp "${./assets/fonts/tabler-icons/tabler-icons.ttf}" \
                  "$out/share/quickshell/dms/assets/fonts/tabler-icons/tabler-icons.ttf"
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0008-livara-tabler-bar-icons.patch}"
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0009-livara-kora-icon-flicker-fix.patch}"
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0010-livara-bar-icon-hd-source-size.patch}"
                patch -p2 -d "$out/share/quickshell/dms" < "${./patches/0011-livara-battery-fallback-icon.patch}"
                # Verify patches landed: each patch introduces a unique marker
                # string that must be present in the installed QML after patching.
                grep -q 'NetworkService\.networkAvailable' "$out/share/quickshell/dms/Modules/ControlCenter/Models/WidgetModel.qml" \
                  || { echo "dms-conf: network-widget patch marker missing in WidgetModel.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_GAME_MODE' "$out/share/quickshell/dms/Modals/PowerMenuModal.qml" \
                  || { echo "dms-conf: game-mode patch marker missing in PowerMenuModal.qml" >&2; exit 1; }
                grep -q 'modelData\.gameMode' "$out/share/quickshell/dms/Modules/Settings/PowerSleepTab.qml" \
                  || { echo "dms-conf: game-mode patch marker missing in PowerSleepTab.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_WEATHER_NO_SKY' "$out/share/quickshell/dms/Modules/DankDash/WeatherTab.qml" \
                  || { echo "dms-conf: weather-sky-graph patch marker missing in WeatherTab.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_POWER_BUTTON' "$out/share/quickshell/dms/Modules/DankBar/Widgets/ControlCenterButton.qml" \
                  || { echo "dms-conf: power-button patch marker missing in ControlCenterButton.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_HIDPI_ICON' "$out/share/quickshell/dms/Modules/DankBar/Widgets/RunningApps.qml" \
                  || { echo "dms-conf: bar-icon-hidpi patch marker missing in RunningApps.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_HIDE_CALENDAR_NO_BACKEND' "$out/share/quickshell/dms/Modules/DankDash/OverviewTab.qml" \
                  || { echo "dms-conf: hide-calendar patch marker missing in OverviewTab.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_TABLER_ICONS' "$out/share/quickshell/dms/Widgets/DankIcon.qml" \
                  || { echo "dms-conf: tabler-bar-icons patch marker missing in DankIcon.qml" >&2; exit 1; }
                test -f "$out/share/quickshell/dms/assets/fonts/tabler-icons/tabler-icons.ttf" \
                  || { echo "dms-conf: Tabler Icons font not installed" >&2; exit 1; }
                grep -q 'LIVARA_DMS_ICON_PREWARM' "$out/share/quickshell/dms/Services/IconThemeService.qml" \
                  || { echo "dms-conf: kora-icon-flicker patch marker missing in IconThemeService.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_ICON_NO_FLICKER_FALLBACK' "$out/share/quickshell/dms/Common/Paths.qml" \
                  || { echo "dms-conf: kora-icon-flicker patch marker missing in Paths.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_ICON_PREWARM' "$out/share/quickshell/dms/Services/AppSearchService.qml" \
                  || { echo "dms-conf: kora-icon-flicker patch marker missing in AppSearchService.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_ICON_HD_SOURCE_SIZE' "$out/share/quickshell/dms/Modules/DankBar/Widgets/FocusedApp.qml" \
                  || { echo "dms-conf: bar-icon-hd patch marker missing in FocusedApp.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_ICON_HD_SOURCE_SIZE' "$out/share/quickshell/dms/Modules/DankBar/Widgets/WorkspaceSwitcher.qml" \
                  || { echo "dms-conf: bar-icon-hd patch marker missing in WorkspaceSwitcher.qml" >&2; exit 1; }
                grep -q 'LIVARA_DMS_BATTERY_FALLBACK' "$out/share/quickshell/dms/Services/BatteryService.qml" \
                  || { echo "dms-conf: battery-fallback patch marker missing in BatteryService.qml" >&2; exit 1; }
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
            patch -p2 -d "$out" < "${./patches/0003-livara-remove-weather-sky-graph.patch}"
            patch -p2 -d "$out" < "${./patches/0004-livara-power-button-fallback.patch}"
            patch -p2 -d "$out" < "${./patches/0006-livara-bar-icon-hidpi-quality.patch}"
            patch -p2 -d "$out" < "${./patches/0007-livara-hide-calendar-when-no-backend.patch}"
            mkdir -p "$out/assets/fonts/tabler-icons"
            cp "${./assets/fonts/tabler-icons/tabler-icons.ttf}" \
              "$out/assets/fonts/tabler-icons/tabler-icons.ttf"
            patch -p2 -d "$out" < "${./patches/0008-livara-tabler-bar-icons.patch}"
            patch -p2 -d "$out" < "${./patches/0009-livara-kora-icon-flicker-fix.patch}"
            patch -p2 -d "$out" < "${./patches/0010-livara-bar-icon-hd-source-size.patch}"
            patch -p2 -d "$out" < "${./patches/0011-livara-battery-fallback-icon.patch}"
            # Verify content-level markers so a silently-rejected patch fails the check.
            grep -q 'NetworkService\.networkAvailable' "$out/Modules/ControlCenter/Models/WidgetModel.qml" \
              || { echo "check: network-widget patch marker missing" >&2; exit 1; }
            grep -q 'LIVARA_DMS_GAME_MODE' "$out/Modals/PowerMenuModal.qml" \
              || { echo "check: game-mode patch marker missing in PowerMenuModal" >&2; exit 1; }
            grep -q 'modelData\.gameMode' "$out/Modules/Settings/PowerSleepTab.qml" \
              || { echo "check: game-mode patch marker missing in PowerSleepTab" >&2; exit 1; }
            grep -q 'LIVARA_DMS_WEATHER_NO_SKY' "$out/Modules/DankDash/WeatherTab.qml" \
              || { echo "check: weather-sky-graph patch marker missing in WeatherTab" >&2; exit 1; }
            grep -q 'LIVARA_DMS_POWER_BUTTON' "$out/Modules/DankBar/Widgets/ControlCenterButton.qml" \
              || { echo "check: power-button patch marker missing in ControlCenterButton" >&2; exit 1; }
            grep -q 'LIVARA_DMS_HIDPI_ICON' "$out/Modules/DankBar/Widgets/RunningApps.qml" \
              || { echo "check: bar-icon-hidpi patch marker missing in RunningApps" >&2; exit 1; }
            grep -q 'LIVARA_DMS_HIDE_CALENDAR_NO_BACKEND' "$out/Modules/DankDash/OverviewTab.qml" \
              || { echo "check: hide-calendar patch marker missing in OverviewTab" >&2; exit 1; }
            grep -q 'LIVARA_DMS_TABLER_ICONS' "$out/Widgets/DankIcon.qml" \
              || { echo "check: tabler-bar-icons patch marker missing in DankIcon.qml" >&2; exit 1; }
            test -f "$out/assets/fonts/tabler-icons/tabler-icons.ttf" \
              || { echo "check: Tabler Icons font not installed" >&2; exit 1; }
            grep -q 'LIVARA_DMS_ICON_PREWARM' "$out/Services/IconThemeService.qml" \
              || { echo "check: kora-icon-flicker patch marker missing in IconThemeService.qml" >&2; exit 1; }
            grep -q 'LIVARA_DMS_ICON_NO_FLICKER_FALLBACK' "$out/Common/Paths.qml" \
              || { echo "check: kora-icon-flicker patch marker missing in Paths.qml" >&2; exit 1; }
            grep -q 'LIVARA_DMS_ICON_PREWARM' "$out/Services/AppSearchService.qml" \
              || { echo "check: kora-icon-flicker patch marker missing in AppSearchService.qml" >&2; exit 1; }
            grep -q 'LIVARA_DMS_ICON_HD_SOURCE_SIZE' "$out/Modules/DankBar/Widgets/FocusedApp.qml" \
              || { echo "check: bar-icon-hd patch marker missing in FocusedApp.qml" >&2; exit 1; }
            grep -q 'LIVARA_DMS_ICON_HD_SOURCE_SIZE' "$out/Modules/DankBar/Widgets/WorkspaceSwitcher.qml" \
              || { echo "check: bar-icon-hd patch marker missing in WorkspaceSwitcher.qml" >&2; exit 1; }
            grep -q 'LIVARA_DMS_BATTERY_FALLBACK' "$out/Services/BatteryService.qml" \
              || { echo "check: battery-fallback patch marker missing in BatteryService.qml" >&2; exit 1; }
          '';
        });
    };
}
