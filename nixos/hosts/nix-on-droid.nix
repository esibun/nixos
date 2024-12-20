{pkgs, ...}:

{
  # TODO: figure out all base config that's missing on nix-on-droid
  environment.packages = with pkgs; [
    findutils
    gnugrep
    openssh
    which
  ];

  home-manager = {
    config = ../../home/hosts/nix-on-droid.nix;
    useGlobalPkgs = true;
  };

  system.stateVersion = "24.05";
}
