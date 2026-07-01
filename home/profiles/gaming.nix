{pkgs, inputs, lib, config, system, ...}:

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
    nte = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon/92d69cf8519a334ced3f55142c811d95.png";
      hash = "sha256-FOB4eQ+8Qj1VLpvMXg3U0NBwkmMZCGMieMaXDUGrb/8=";
    };
    wuwa = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon/9d435d2e017f7a7384f4e1c6a6f2d169.png";
      hash = "sha256-pBJnQ7kyCyGRv7Tdu3l1e7wELKLLLLN4Hd9hZQQWsy4=";
    };
  };
  callPackage = pkgs.lib.callPackageWith (pkgs // {
    gamePrefix = "${pkgs.mangohud}/bin/mangohud ${pkgs.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture";
    inherit config;
  });
  compatTool = pkg: lib.makeSearchPathOutput "steamcompattool" "" [ pkg ];
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
        launcherBinary = "GRYPHLINK/Launcher.exe";
        mainBinary = "Arknights Endfield/Endfield.exe";
        icon = icons.endfield;
        useUmu = true;
        scriptPre = "export GAMESCOPE_ENABLE_WSI=0"; # required for lsvk support
        extraGamescopeFlags = "--force-grab-cursor"; # prevent cursor getting stuck at edge of screen and preventing camera movement
        customProtonPath = compatTool inputs.dwproton.packages.${system}.dw-proton;
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
          libmpg123
          ffmpeg_4-headless # GStreamer H.264 support
          freetype
          harfbuzz
        ];
        customProtonPath = compatTool (pkgs.unstable.proton-ge-bin.overrideAttrs(old: {
          src = fetchzip {
            url = "https://github.com/Open-Wine-Components/umu-proton/releases/download/UMU-Proton-9.0-4e/UMU-Proton-9.0-4e.tar.gz";
            hash = "sha256-YwrDmdNEeqE4DCnfEgo1bQv0GnMqaP0PcbVyV2JLbEE=";
          };
          preFixup = ""; # prevent unnecessary rename causing a build failure
        }));
      })
      (callPackage ../pkgs/wine-game.nix {
        title = "Neverness to Everness";
        baseDir = "${config.home.homeDirectory}/.local/share/games/nte";
        shortname = "nte";
        installerUrl = "https://ntecdn1.perfectworld.com/clientRes/installer-Global/YH_Singapore_common_setup_1.0.6.0423_20260424.exe";
        launcherBinary = "Neverness To Everness/NTEGlobalLauncher.exe";
        mainBinary = "Neverness To Everness/NTEGlobalLauncher.exe";
        gamePostfix = "/autoplay";
        icon = icons.nte;
        useUmu = true;
        extraGamescopeFlags = "--force-grab-cursor"; # prevent cursor getting stuck at edge of screen and preventing camera movement
        customProtonPath = compatTool inputs.dwproton.packages.${system}.dw-proton;
      })
      (callPackage ../pkgs/wine-game.nix {
        title = "Wuthering Waves";
        baseDir = "${config.home.homeDirectory}/.local/share/games/wuwa";
        shortname = "wuwa";
        # Unfortunately WuWa's website uses complicated javascript+JSON to grab the download URL, there is no simple URL redirect
        installerUrl = "https://mirrors-package-mc.aki-game.net/client/download/20260423185747_sepu4waAMJhWDkBjgS/WutheringWaves_overseas_setup_2.6.1.0.exe";
        launcherBinary = "Wuthering Waves/launcher.exe";
        mainBinary = "Wuthering Waves/Wuthering Waves Game/Wuthering Waves.exe";
        scriptPre = "${pkgs.writeTextFile {
          name = "ensure-wuwa-patches";
          text = ''
            #!/usr/bin/env bash

            # --------
            # Patch launcher appearing fully transparent
            # --------
            cd $HOME/.local/share/games/wuwa/game/Wuthering\ Waves
            # switch to latest game data directory
            cd $(ls -td -- *.*/ | head -n1)
            mkdir -p ${config.home.homeDirectory}/.local/share/games/wuwa/backup
            NOT_PATCHED=$(strings launcher_main.dll | grep AllowsTransparency | wc -l)
            if [ $NOT_PATCHED -gt 0 ]; then
              mv launcher_main.dll launcher_main.dll.bak
              ${pkgs.bbe}/bin/bbe -e "s/\x12AllowsTransparency/\x09IsEnabled\x1bA\x00\x03AAAAA/" launcher_main.dll.bak > launcher_main.dll
              mv launcher_main.dll.bak ${config.home.homeDirectory}/.local/share/games/wuwa/backup/launcher_main.dll
            fi

            # -------
            # Prevent one-time disconnect at around 10 minutes
            # -------
            cd $HOME/.local/share/games/wuwa/game/Wuthering\ Waves/Wuthering\ Waves\ Game/Client/Binaries/Win64/ThirdParty/KrPcSdk_Global/KRSDKRes
            NOT_PATCHED=$(strings KRSDK.bin | grep "KR_ChannelID=240" | wc -l)
            if [ $NOT_PATCHED -gt 0 ]; then
              mv KRSDK.bin KRSDK.bin.bak
              ${pkgs.bbe}/bin/bbe -e "s/KR_ChannelID=240/KR_ChannelID=205/" KRSDK.bin.bak > KRSDK.bin
              mv KRSDK.bin.bak ${config.home.homeDirectory}/.local/share/games/wuwa/backup/KRSDK.bin
            fi
          '';
          executable = true;
          destination = "/bin/ensure-wuwa-patches";
        }}/bin/ensure-wuwa-patches"; # patch out AllowTransparency as this bugs out launcher window; see jadeite#69
        commandPrefix = "env SteamOS=1"; # inform wuwa ac we're on linux
        gamePostfix = "-dx11"; # use dx11 (better performance)
        icon = icons.wuwa;
        useUmu = true;
        extraGamescopeFlags = "--force-grab-cursor"; # prevent cursor getting stuck at edge of screen and preventing camera movement
        customProtonPath = compatTool pkgs.unstable.proton-ge-bin; # normal proton doesn't have correct codec for videos
      })

      # Game Tools
      gamescope
      gamescope-wsi
      lsfg-vk
      lsfg-vk-ui
      mangohud
      (steam.override {
        # gamescope fixes
        extraPkgs = pkgs: with pkgs; [
          libxcursor
          libxi
          libxinerama
          libxscrnsaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
        ];
      })

      # Utilities
      crosspipe # useful for rerouting game audio
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

    xdg.dataFile = {
      # install LSFG vulkan layer
      lsfg = {
        source = "${pkgs.lsfg-vk}/share/vulkan/implicit_layer.d/VkLayer_LS_frame_generation.json";
        target = "vulkan/implicit_layer.d/VkLayer_LS_frame_generation.json";
      };
    };
  };
}
