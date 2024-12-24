{pkgs, ...}:

{
  imports = [
    ../common.nix

    ../profiles/desktop.nix
    ../profiles/gaming.nix
    ../profiles/gaming-beatoraja.nix
    ../profiles/vfio.nix
  ];

  home = {
    homeDirectory = "/home/esi";
    packages = with pkgs; [
      borgbackup
      fcast-receiver
      libnotify
      qbittorrent
    ];
    stateVersion = "23.11";
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
    workspaceOutputAssign = [
      {
        workspace = "1";
        output = "DP-1";
      }
      {
        workspace = "2";
        output = "DP-2";
      }
      {
        workspace = "3";
        output = "DP-2";
      }
      {
        workspace = "4";
        output = "DP-2";
      }
      {
        workspace = "5";
        output = "DP-2";
      }
    ];
  };
}
