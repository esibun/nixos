{pkgs, config, ...}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // {
    gamePrefix = "${pkgs.mangohud}/bin/mangohud ${pkgs.unstable.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture";
    inherit config;
  });
  icons = {
    xsanity = pkgs.fetchurl {
      url = "https://xsanity.net/assets/img/extras/logos/800x800.png";
      hash = "sha256-pZlqCXCX54GeHroN4W4y4x3sVRlGmqy8OC0TLvAMosY=";
    };
  };
in
{
  home.packages = with pkgs; [
    (callPackage ../pkgs/native-game.nix {
      title = "XSanity";
      baseDir = "${config.home.homeDirectory}/.local/share/games/xsanity";
      shortname = "xsanity";
      mainBinary = "XSanity";
      # obs-gamecapture hates injecting into opengl games for some reason, unknown reason
      gamePrefix = "env LD_PRELOAD=$\{LD_PRELOAD\}:${pkgs.unstable.obs-studio-plugins.obs-vkcapture}/lib/obs_glcapture/libobs_glcapture.so";
      icon = icons.xsanity;
    })
  ];
}
