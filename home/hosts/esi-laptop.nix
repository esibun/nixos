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
    username = "esi";
  };
}
