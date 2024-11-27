{pkgs, ...}:

{
  imports = [
    ../common.nix

    ../modules/desktop.nix
    ../modules/gaming.nix
    ../modules/gaming-beatoraja.nix
  ];

  home = {
    homeDirectory = "/home/esi";
    packages = with pkgs; [
      borgbackup
      fcast-receiver
      libnotify
    ];
    username = "esi";
  };
}
