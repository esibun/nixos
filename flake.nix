{
  description = "NixOS Configuration for esi";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, aagl, ...}: {
    nixosConfigurations = {
      esi-nixos = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        modules = [
          {
            nixpkgs.config.allowUnfree = true; # for stable
            nixpkgs.overlays = [
              (final: prev: {
                unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;
                };
              })
            ];
          }

          ./nixos/common.nix
          ./nixos/vfio.nix
          ./nixos/hosts/esi-nixos.nix

          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit aagl;
              };
              users.esi = import ./home/hosts/esi-nixos.nix;
            };
          }
        ];
      };
      esi-laptop = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        modules = [
          {
            nixpkgs.config.allowUnfree = true; # for stable
            nixpkgs.overlays = [
              (final: prev: {
                unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;
                };
              })
            ];
          }

          nixos-hardware.nixosModules.framework-16-7040-amd

          ./nixos/common.nix
          ./nixos/hosts/esi-laptop.nix

          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit aagl;
              };
              users.esi = import ./home/hosts/esi-laptop.nix;
            };
          }
        ];
      };
    };
  };
}
