{pkgs, ...}:

{
  imports = [
    ../common.nix

    ../modules/desktop.nix
    ../modules/gaming.nix
    ../modules/gaming-beatoraja.nix
    ../modules/vfio.nix
  ];

  home = {
    homeDirectory = "/home/esi";
    packages = with pkgs; [
      borgbackup
      fcast-receiver
      libnotify
      qbittorrent
    ];
    username = "esi";
  };
}
