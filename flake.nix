{
  description = "NixOS Configuration for esi";

  inputs = {
    #
    # OS Level Packages
    #
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-avf.url = "https://github.com/nix-community/nixos-avf/releases/download/nixos-25.05/avf-channel-25.05-aarch64.tar.xz";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #
    # Config Support Level Packages
    #
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = ""; # don't pull darwin deps
      };
    };

    #
    # App Level Packages
    #
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-needsreboot.url = "github:thefossguy/nixos-needsreboot";

    #
    # Non-Flake Inputs
    #
    genshin-fpsunlock = {
      url = "https://codeberg.org/mkrsym1/fpsunlock/releases/download/latest/fpsunlock.exe";
      flake = false;
    };

    rofi-adi1090x = {
      url = "github:adi1090x/rofi";
      flake = false;
    };

    secrets = {
      url = "git+ssh://git@github.com/esibun/nixos-secrets.git";
      flake = false;
    };
  };

  outputs = inputs@{self, nixpkgs, nixpkgs-unstable, ...}: let
    commonx64Modules = let
      system = "x86_64-linux";
    in [
      {
        nixpkgs = {
          config.allowUnfree = true; # for stable
          overlays = let
            pkgs = nixpkgs.legacyPackages.${system};
          in [
            (final: prev: rec {
              unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
              # use an updated gamelist for arrpc
              arrpc = pkgs.arrpc.overrideAttrs(final: prev: {
                patches = [
                  ./files/arrpc-gamelist.patch
                ];
              });
              # use unstable comma to fix args change to nix-index dependency (see nix-community/comma#103)
              comma = unstable.comma;
              # patch gamescope using unsupported scrgb extensions
              gamescope = pkgs.gamescope.overrideAttrs(final: prev: {
                patches = prev.patches ++ [
                  (pkgs.fetchpatch {
                    url = "https://patch-diff.githubusercontent.com/raw/ValveSoftware/gamescope/pull/1867.patch";
                    hash = "sha256-ONjSInJ7M8niL5xWaNk5Z16ZMcM/A7M7bHTrgCFjrts=";
                  })
                ];
              });
            })
          ];
        };
      }

      inputs.agenix.nixosModules.default

      ./nixos/common.nix
      ./nixos/secrets.nix
    ];
  in {
    nixosConfigurations = {
      esi-nixos = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        modules = commonx64Modules ++ [
          ./nixos/profiles/baremetal.nix
          ./nixos/profiles/desktop.nix
          ./nixos/profiles/gaming.nix
          ./nixos/profiles/vfio.nix
          ./nixos/hosts/esi-nixos.nix

          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs system;
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
        modules = commonx64Modules ++ [
          inputs.nixos-hardware.nixosModules.framework-16-7040-amd

          ./nixos/profiles/baremetal.nix
          ./nixos/profiles/desktop.nix
          ./nixos/profiles/gaming.nix
          ./nixos/hosts/esi-laptop.nix

          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs system;
              };
              users.esi = import ./home/hosts/esi-laptop.nix;
            };
          }
        ];

        specialArgs = {
          inherit inputs;
        };
      };
      linode = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        modules = commonx64Modules ++ [
          # non-public config file since this machine is public facing
          "${inputs.secrets}/profiles/linode.nix"

          ./nixos/hosts/linode.nix
        ];

        specialArgs = {
          inherit inputs;
        };
      };
      esi-razer = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        modules = commonx64Modules ++ [
          ./nixos/profiles/baremetal.nix
        ];

        specialArgs = {
          inherit inputs;
        };
      };
    };
  };
}
