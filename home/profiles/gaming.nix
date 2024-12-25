{pkgs, inputs, config, ...}:

let
  defaultGamescopeFlags = "-F fsr -b";
in
{
  home.packages = with pkgs; [
    # Games
    inputs.aagl.packages.${system}.anime-game-launcher
    prismlauncher
    inputs.xivlauncher-rb.packages.${system}.default

    (callPackage ../pkgs/wine-game.nix {
      umu = inputs.umu.packages.${system}.umu;
      title = "Girls' Frontline 2: Exilium";
      baseDir = "${config.home.homeDirectory}/.local/share/games/gfl2";
      shortname = "gfl2";
      installerUrl = "https://gf2-us-cdn-launcher.sunborngame.com/prod/download/launcher/1.0.0/GF2_Launcher_pc1_1_0_0_OverSeas_Mica_1732302259_6_1000005.exe";
      launcherBinary = "GFL2Exilium/PCLauncher.exe";
      mainBinary = "GFL2Exilium/GF2_Exilium.exe";
      icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon_thumb/9f2dab581c42e1381065d4d6dbd75d1a.png";
        hash = "sha256-NXDkBBgIOUuaqG3gVtftrGz7Wa2hOAmnEEzMuaM0VsI=";
      };
      winetricksVerbs = [
        "allfonts"
        "dotnet8"
      ];
      gamescopeFlags = defaultGamescopeFlags;
    })


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

    # Utilities
    helvum # useful for rerouting game audio
  ];

  wayland.windowManager.sway.config.startup = [
    { command = "${pkgs.steam}/bin/steam -silent"; }
  ];
}
