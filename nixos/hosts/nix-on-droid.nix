{pkgs, ...}:

{
  # TODO: import requiredPackages here from base nix

  home-manager = {
    config = ../../home/hosts/nix-on-droid.nix;
    useGlobalPkgs = true;
  };

  system.stateVersion = "24.05";
}
