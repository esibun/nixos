{pkgs, config, ...}:

let
  beatorajaScript = pkgs.writeTextFile {
    name = "beatoraja-launcher";
    text = ''
      #!/usr/bin/env bash

      export _JAVA_OPTIONS='-Dsun.java2d.opengl=true -Djdk.gtk.version=2 -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dfile.encoding=UTF-8'
      export LD_LIBRARY_PATH="${config.home.homeDirectory}/.local/share/games/bms:$LD_LIBRARY_PATH"
      export BASEDIR="${config.home.homeDirectory}/.local/share/games/bms"

      cd $BASEDIR
      exec env SHUT_UP_TACHI=yes ${pkgs.steam-run}/bin/steam-run jre/bin/java -Xms4g -Xmx16g -Xdiag -cp beatoraja.jar:ir/* bms.player.beatoraja.MainLoader $@
    '';
    executable = true;
    destination = "/bin/beatoraja";
  };
  callPackage = pkgs.lib.callPackageWith (pkgs // {
    gamePrefix = "${pkgs.mangohud}/bin/mangohud ${pkgs.unstable.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture";
    inherit config;
  });
  icons = {
    beatoraja = pkgs.fetchurl {
      url = "https://images.sftcdn.net/images/t_app-icon-s/p/47d51c3c-7677-487a-b486-6a887aeabac2/2686950718/beatoraja-logo";
      hash = "sha256-ZZ+A1tKk+CNT+BL8K0GHgmYURKrGqtq3pzpk0v1aZFU=";
    };
  };
in
{
  home.packages = with pkgs; [
    (callPackage ../pkgs/native-game.nix {
      title = "Beatoraja";
      baseDir = "${config.home.homeDirectory}/.local/share/games/bms";
      shortname = "beatoraja";
      useGlobalPaths = true;
      launcherBinary = "${beatorajaScript}/bin/beatoraja";
      mainBinary = "${beatorajaScript}/bin/beatoraja";
      # obs-gamecapture hates injecting into opengl games for some reason, unknown reason
      gamePrefix = "env LD_PRELOAD=$\{LD_PRELOAD\}:${pkgs.unstable.obs-studio-plugins.obs-vkcapture}/lib/obs_glcapture/libobs_glcapture.so";
      gamePostfix = "-s";
      icon = icons.beatoraja;
      extraBin = [
        xorg.xrandr # java can't initialize monitors without this for some reason
      ];
    })
  ];
}
