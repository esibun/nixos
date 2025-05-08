{pkgs, ...}:

{
  imports = [
    ../common.nix

    ../profiles/desktop.nix
    ../profiles/gaming.nix
    ../profiles/gaming-beatoraja.nix
  ];

  gamescopeFlags = "-w 2560 -h 1600 -r 144 -F fsr -b";

  home = {
    homeDirectory = "/home/esi";
    packages = with pkgs; [
      brightnessctl
    ];
    stateVersion = "23.11";
    username = "esi";
  };

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-2, preferred, auto, 1, vrr, 0"
    ];
    bind = [
      ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%+"
      ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%-"
    ];
    workspace = [
      "1, monitor:DP-1"
      "2, monitor:DP-2"
      "3, monitor:DP-2"
      "4, monitor:DP-2"
      "5, monitor:DP-2"
    ];
  };
}
