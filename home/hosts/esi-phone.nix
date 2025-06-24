
{pkgs, ...}:

{
  imports = [
    ../common.nix
  ];

  home = {
    homeDirectory = "/home/droid";
    stateVersion = "25.05";
    username = "droid";
  };
}
