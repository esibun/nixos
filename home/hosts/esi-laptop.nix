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
      # todo: some of these should be modules
      brightnessctl
      libnotify
      protonvpn-gui
      wluma
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
