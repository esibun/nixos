{
  description = "NixOS Configuration for esi";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {self, nixpkgs, nixpkgs-unstable, ...}: {
    nixosConfigurations = {
      esi-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/common.nix
          ./nixos/vfio.nix
          ./nixos/hosts/esi-nixos.nix
        ];
      };
    };
  };
}
