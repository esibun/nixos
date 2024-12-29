{pkgs, inputs, config, ...}:

let
  defaultGamescopeFlags = "-F fsr -b";
  reaper = {
    python = pkgs.python3.withPackages (python-pkgs: [python-pkgs.i3ipc]);
    script = ../../files/scripts/reaper.py;
  };
  # explicitly include dotnet8, this isn't in winetricks stable yet
  dotnet8 = ../../files/dotnet8.verb;
in
{
  home.packages = with pkgs; [
    # Games
    inputs.aagl.packages.${system}.anime-game-launcher
    prismlauncher
    inputs.xivlauncher-rb.packages.${system}.default

    (callPackage ../pkgs/wine-game.nix {
      inherit inputs;
      title = "Girls' Frontline 2: Exilium";
      baseDir = "${config.home.homeDirectory}/.local/share/games/gfl2";
      shortname = "gfl2";
      installerUrl = "https://gf2-us-cdn-launcher.sunborngame.com/prod/download/launcher/1.0.0/GF2_Launcher_pc1_1_0_0_OverSeas_Mica_1732302259_6_1000005.exe";
      launcherBinary = "GF2Exilium/PCLauncher.exe";
      mainBinary = "GF2Exilium/GF2_Exilium.exe";
      icon = pkgs.fetchurl {
        url = "https://cdn2.steamgriddb.com/icon_thumb/9f2dab581c42e1381065d4d6dbd75d1a.png";
        hash = "sha256-NXDkBBgIOUuaqG3gVtftrGz7Wa2hOAmnEEzMuaM0VsI=";
      };
      useUmu = false;
      winetricksVerbs = [
        "allfonts"
        "${dotnet8}"
      ];
      gamescopeFlags = defaultGamescopeFlags;
      extraLib = [
        ffmpeg_4-headless # GStreamer H.264 support
      ];
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

  systemd = {
    user.services.game-reaper = {
      Unit = {
        Description = "Cleans up game's systemd scopes after the main window closes, closing leftover programs";
        Wants = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${reaper.python}/bin/python ${reaper.script}";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };

  wayland.windowManager.sway.config.startup = [
    { command = "${pkgs.steam}/bin/steam -silent"; }
  ];
}
