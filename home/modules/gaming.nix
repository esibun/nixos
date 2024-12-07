{pkgs, aagl, ...}:

{
  home.packages = with pkgs; [
    # Games
    aagl.packages.${system}.anime-game-launcher
    prismlauncher

    # Game Tools
    gamescope
    (lutris.override {
      # fix gfl2 (needs ffmpeg libs for H.264)
      extraLibraries = pkgs: with pkgs; [
        ffmpeg_4-headless
      ];
    })
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
      version = "1.1.1.5";
      src = pkgs.fetchFromGitHub {
        owner = "rankynbass";
        repo = "XIVLauncher.Core";
        rev = "rb-v1.1.1.5";
        hash = "sha256-gGTxU80vvZTwUs/ulzrKikSBKIgB0VHFmVtwbOw7x38=";
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
