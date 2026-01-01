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
    genshin = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon_thumb/65ae27b8c33157282761f37083da12dd.png";
      hash = "sha256-IYUQR8JPkXprJ7xBbmbzroPzhIg8g1J/bHZXORfvUHo=";
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
      fflogs
      prismlauncher

      (callPackage ../pkgs/wine-game.nix {
        title = "Genshin Impact";
        baseDir = "${config.home.homeDirectory}/.local/share/games/genshin";
        shortname = "genshin";
        installerUrl = "https://sg-public-api.hoyoverse.com/event/download_porter/trace/ys_global/genshinimpactpc/default?appid=723";
        useGlobalPaths = true;
        launcherBinary = "${config.home.homeDirectory}/.local/share/games/genshin/game/HoYoPlay/launcher.exe";
        mainBinary = "${pkgs.writeTextFile {
          name = "genshin-launch";
          text = ''
            Z:

            cd "${config.home.homeDirectory}/.local/share/games/genshin/game/HoYoPlay/games/Genshin Impact game"
            start GenshinImpact.exe

            cd "${config.home.homeDirectory}/.local/share/games/genshin"
            start /wait fpsunlock.exe 144 1000
          '';
          destination = "/bin/launch.bat";
        }}/bin/launch.bat";
        icon = icons.genshin;
        useUmu = true;
        winetricksVerbs = [
          "vcrun2022"
        ];
        # Genshin requires cursor grab to avoid cursor state issues (camera)
        extraGamescopeFlags = "--force-grab-cursor --cursor-scale-height 1080";
        gamePrefix = "${pkgs.mangohud}/bin/mangohud";
        # wine doesn't appreciate being given a windows executable without the correct extension
        commandPrefix = "${pkgs.coreutils}/bin/ln -sf ${inputs.genshin-fpsunlock} ~/.local/share/games/genshin/fpsunlock.exe && ";
      })
      (callPackage ../pkgs/wine-game.nix {
        title = "Girls' Frontline 2: Exilium";
        baseDir = "${config.home.homeDirectory}/.local/share/games/gfl2";
        shortname = "gfl2";
        installerUrl = "https://gf2-us-cdn.sunborngame.com/prod/download/launcher/1.0.2/GF2_Launcher_pc1_1_0_0_OverSeas_Mica_1747250420_12_1000005.exe";
        launcherBinary = "GF2Exilium/PCLauncher.exe";
        mainBinary = "GF2Exilium/GF2 Game/GF2_Exilium.exe";
        icon = icons.gfl2;
        useUmu = true;
        winetricksVerbs = [
          "dotnetcore3"
        ];
        extraLib = [
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
