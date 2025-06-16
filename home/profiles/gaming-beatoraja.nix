{pkgs, config, ...}:

{
  home.packages = with pkgs; [
    (callPackage ../pkgs/native-game.nix {
      title = "Beatoraja";
      baseDir = "${config.home.homeDirectory}/.local/share/games/bms";
      shortname = "beatoraja";
      mainBinary = "beatoraja.sh";
      # TODO: icon?
      # mangohud from gamescope; in-process breaks obs-gamecapture
      gamescopeFlags = config.gamescopeFlags + " --mangoapp";
      extraBin = [
        steam-run
        xorg.xrandr
      ];
      commandPrefix = "env SHUT_UP_TACHI=yes";
      gamePrefix = "${pkgs.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture";
      commandPostfix = "-s";
    })
  ];
}
