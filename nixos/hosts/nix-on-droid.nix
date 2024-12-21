{pkgs, ...}:

# IMPORTANT NOTE:
# The subset of config values available to nix-on-droid is NOT the
#  same as those available to NixOS.  Please refer to the following
#  config module for actual available options:
#  https://github.com/nix-community/nix-on-droid/tree/master/modules
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

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "24.05";
}
