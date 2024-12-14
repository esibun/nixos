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

  wayland.windowManager.sway.config = {
    output = {
      "DP-1" = {
        resolution = "3840x2160@144Hz";
        position = "0,0";
        scale = "1";
        adaptive_sync = "on";
      };
      "DP-2" = {
        resolution = "1920x1080@144Hz";
        position = "3840,0";
        scale = "1";
      };
    };
    startup = [
      { command = "${pkgs.plasma5Packages.kdeconnect-kde}/bin/kdeconnect-indicator"; }
    ];
  };
}
