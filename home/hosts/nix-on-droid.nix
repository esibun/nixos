{pkgs, ...}:

{
  imports = [
    ../common.nix
  ];

  home = {
    homeDirectory = "/data/data/com.termux.nix/files/home";
    stateVersion = "24.05";
    username = "nix-on-droid";
  };
}
