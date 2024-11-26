{pkgs, aagl, ...}:

{
  home.packages = with pkgs; [
    # Games
    aagl.packages.${system}.anime-game-launcher
    prismlauncher

    # Game Tools
    gamescope
    lutris
    mangohud
    (steam.override {
      # gamescope fixes
      extraPkgs = pkgs: with pkgs; [
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
      ];
    })
    (xivlauncher.overrideAttrs(final: prev: {
      src = pkgs.fetchFromGitHub {
        owner = "rankynbass";
        repo = "XIVLauncher.Core";
        rev = "rb-v1.1.1.3";
        hash = "sha256-hh0h4+cRMb+ZECsMc2WuVeyuJSUCMBwqMVazct5/gHY=";
        fetchSubmodules = true;
      };
    }))

    # Dependencies
    chromium # for cactus watcher

    # Utilities
    helvum # useful for rerouting game audio
    looking-glass-client
  ];
}
