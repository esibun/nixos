{pkgs, inputs, ...}:

{
  home.packages = with pkgs; [
    # Games
    inputs.aagl.packages.${system}.anime-game-launcher
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
    inputs.xivlauncher-rb.packages.${system}.default

    # Dependencies
    chromium # for cactus watcher

    # Utilities
    helvum # useful for rerouting game audio
    looking-glass-client
  ];
}
