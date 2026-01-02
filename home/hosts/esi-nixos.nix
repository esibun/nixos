{pkgs, ...}:

{
  imports = [
    ../common.nix

    ../profiles/desktop.nix
    ../profiles/gaming.nix
    ../profiles/gaming-beatoraja.nix
    ../profiles/vfio.nix
  ];

  gamescopeFlags = "-w 3840 -h 2160 -r 480 -F fsr --hdr-enabled -f";

  home = {
    homeDirectory = "/home/esi";
    packages = with pkgs; [
      fcast-receiver
      libimobiledevice
      qbittorrent
    ];
    stateVersion = "23.11";
    username = "esi";
  };

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1, 3840x2160@240, 0x0, 1, bitdepth, 10, cm, hdr, vrr, 1"
      "DP-2, 3840x2160@144, 3840x-200, 1, vrr, 1"
      "HDMI-A-1, 1920x1080@60, 0x0, 1"
    ];
    exec = [
      "${pkgs.uwsm}/bin/uwsm app -- ${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
    ];
    input = {
      sensitivity = -0.333;
      accel_profile = "flat";
    };
    workspace = [
      "1, monitor:DP-1"
      "2, monitor:DP-2"
      "3, monitor:DP-2"
      "4, monitor:DP-2"
      "5, monitor:DP-2"
    ];
  };
}
