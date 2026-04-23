{pkgs, inputs, lib, config, ...}:

let
  reaper = {
    python = pkgs.python3.withPackages (python-pkgs: [python-pkgs.i3ipc]);
    script = ../../files/scripts/reaper.py;
  };
  swaymode = {
    python = pkgs.python3.withPackages (python-pkgs: [python-pkgs.i3ipc]);
    script = ../../files/scripts/swaymode.py;
  };
  icons = {
    endfield = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon/a2959d14ad418268c4ecf73fb183ab8f.png";
      hash = "sha256-H9HZYjshD350cUMghf7OlFjX8FXvoQug4fRl4HgB89U=";
    };
    gfl2 = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon_thumb/9f2dab581c42e1381065d4d6dbd75d1a.png";
      hash = "sha256-NXDkBBgIOUuaqG3gVtftrGz7Wa2hOAmnEEzMuaM0VsI=";
    };
  };
  callPackage = pkgs.lib.callPackageWith (pkgs // {inherit config;});
in
{
  options = {
    gamescopeFlags = lib.mkOption {
      default = "";
      description = ''
        Flags to pass to Gamescope when launching programs
      '';
    };
  };
  config = {
    home.packages = with pkgs; [
      # Games
      ares
      prismlauncher

      (callPackage ../pkgs/wine-game.nix {
        title = "Arknights: Endfield";
        baseDir = "${config.home.homeDirectory}/.local/share/games/endfield";
        shortname = "endfield";
        installerUrl = "https://launcher.gryphline.com/launcher/get_latest_launcher?appcode=TiaytKBUIEdoEwRT&ta=endfield&channel=6&sub_channel=6";
        launcherBinary = "GRYPHLINK/1.3.0/Games.exe"; # TODO: autodetect latest version folder
        mainBinary = "GRYPHLINK/1.3.0/Games.exe"; # TODO: autodetect latest version folder
        icon = icons.endfield;
        useUmu = true;
        customProtonPath = "${config.home.homeDirectory}/.local/share/Steam/compatibilitytools.d/dwproton-10.0-21-x86_64"; # TODO: bring dwproton into flake
      })
      (callPackage ../pkgs/wine-game.nix {
        title = "Girls' Frontline 2: Exilium";
        baseDir = "${config.home.homeDirectory}/.local/share/games/gfl2";
        shortname = "gfl2";
        installerUrl = "https://gf2-us-cdn.sunborngame.com/prod/download/launcher/1.0.2/GF2_Launcher_pc1_1_0_0_OverSeas_Mica_1747250420_12_1000005.exe";
        launcherBinary = "GF2Exilium/PCLauncher.exe";
        mainBinary = "GF2Exilium/GF2 Game/GF2_Exilium.exe";
        gamePrefix = "${pkgs.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture";
        icon = icons.gfl2;
        useUmu = true;
        winetricksVerbs = [
          "dotnetcore3"
        ];
        extraLib = [
          libmpg123
          ffmpeg_4-headless # GStreamer H.264 support
          freetype
          harfbuzz
        ];
      })


      # Game Tools
      gamescope
      gamescope-wsi
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
          Description = "Game Process Reaper";
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
      user.services.sway-mode = {
        Unit = {
          Description = "Sway Gaming Mode Daemon";
          Wants = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${swaymode.python}/bin/python ${swaymode.script}";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };

    wayland.windowManager.hyprland.settings.exec = [
      "pidof steam || ${pkgs.uwsm}/bin/uwsm app -- ${pkgs.steam}/bin/steam -silent"
    ];
  };
}
