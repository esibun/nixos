{pkgs, config, ...}:

{
  home.packages = with pkgs; [
    steam-run

    (callPackage ../pkgs/native-game.nix {
      title = "Beatoraja";
      baseDir = "/mnt/nvme/bms/LR2oraja";
      shortname = "beatoraja";
      mainBinary = "beatoraja.sh";
      # TODO: icon?
      gamescopeFlags = config.gamescopeFlags;
      extraBin = [
        xorg.xrandr
      ];
      commandPrefix = "env SHUT_UP_TACHI=yes";
      gamePrefix = "${pkgs.mangohud}/bin/mangohud ${pkgs.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture";
      commandPostfix = "-s";
    })
  ];
}
