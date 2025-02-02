{
  description = "NixOS Configuration for esi";

  inputs = {
    #
    # OS Level Packages
    #
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      # nix-on-droid hasn't updated to 24.11, follow unstable (nix-on-droid#429)
      url = "github:nix-community/nix-on-droid";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    #
    # App Level Packages
    #
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    umu = {
      url = "git+https://github.com/Open-Wine-Components/umu-launcher/?dir=packaging\/nix&submodules=1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    xivlauncher-rb = {
      url = "github:drakon64/nixos-xivlauncher-rb";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #
    # Non-Flake Inputs
    #
    catppuccin-swaync-mocha = {
      url = "https://github.com/catppuccin/swaync/releases/latest/download/mocha.css";
      flake = false;
    };

    genshin-fpsunlock = {
      url = "https://codeberg.org/mkrsym1/fpsunlock/releases/download/latest/fpsunlock.exe";
      flake = false;
    };
  };

  outputs = inputs@{self, nixpkgs, nixpkgs-unstable, ...}: {
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
          ./nixos/profiles/desktop.nix
          ./nixos/profiles/gaming.nix
          ./nixos/profiles/vfio.nix
          ./nixos/hosts/esi-nixos.nix

          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs;
              };
              users.esi = import ./home/hosts/esi-nixos.nix;
            };
          }
        ];

        specialArgs = {
          inherit inputs;
        };
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

          inputs.nixos-hardware.nixosModules.framework-16-7040-amd

          ./nixos/common.nix
          ./nixos/profiles/desktop.nix
          ./nixos/profiles/gaming.nix
          ./nixos/hosts/esi-laptop.nix

          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs;
              };
              users.esi = import ./home/hosts/esi-laptop.nix;
            };
          }
        ];

        specialArgs = {
          inherit inputs;
        };
      };
    };
    nixOnDroidConfigurations = {
      default = let
        system = "aarch64-linux";
      in inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # for stable
          overlays = [
            (final: prev: {
              unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            })
          ];
        };
        modules = [
          ./nixos/hosts/nix-on-droid.nix
        ];
      };
    };
  };
}
