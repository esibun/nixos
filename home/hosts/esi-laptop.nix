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

  wayland.windowManager.sway.config = {
    keybindings = {
      "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl s 10%+";
      "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl s 10%-";
    };
    output = {
      "eDP-2" = {
        adaptive_sync = "off";
      };
    };
  };
}
