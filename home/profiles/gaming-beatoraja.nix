{pkgs, config, ...}:

{
  home.packages = with pkgs; [
    (callPackage ../pkgs/native-game.nix {
      title = "Beatoraja";
      baseDir = "${config.home.homeDirectory}/.local/share/games/bms";
      shortname = "beatoraja";
      mainBinary = "beatoraja.sh";
      # TODO: icon?
      gamescopeFlags = config.gamescopeFlags;
      extraBin = [
        steam-run
        xorg.xrandr
      ];
      commandPrefix = "env SHUT_UP_TACHI=yes";
      gamePrefix = "${pkgs.mangohud}/bin/mangohud ${pkgs.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture";
      commandPostfix = "-s";
    })
  ];
}
