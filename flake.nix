{
  description = "Local Noctalia runtime contract for Livara";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, noctalia, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in {
      packages = forEachSystem (system: {
        default = noctalia.packages.${system}.default;
      });

      overlays.default = final: prev: {
        noctalia = noctalia.packages.${final.system}.default;
      };

      homeModules.default = { config, lib, pkgs, ... }:
        {
          imports = [ noctalia.homeModules.default ];
          programs.noctalia = {
            package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.default;
            systemd.enable = lib.mkForce false;
          };
        };

      homeModules.noctalia = self.homeModules.default;
    };
}
