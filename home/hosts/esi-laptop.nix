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
    output = {
      "eDP-2" = {
        adaptive_sync = "on";
      };
    };
  };
}
