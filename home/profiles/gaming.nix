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
    arknights = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon/7298332f04ac004a0ca44cc69ecf6f6b.png";
      hash = "sha256-PEI6T6O6ln++zEyb9TaKnPbqzaghB7bqnBBymL+Rhhk=";
    };
    beatoraja = pkgs.fetchurl {
      url = "https://images.sftcdn.net/images/t_app-icon-s/p/47d51c3c-7677-487a-b486-6a887aeabac2/2686950718/beatoraja-logo";
      hash = "sha256-ZZ+A1tKk+CNT+BL8K0GHgmYURKrGqtq3pzpk0v1aZFU=";
    };
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
  # convenience handler to let us specify proton tool in the same way nixpkgs uses it
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

      # Arknights
      #
      # No issues to report, it just works!
      (callPackage ../pkgs/wine-game.nix {
        title = "Arknights";
        baseDir = "${config.home.homeDirectory}/.local/share/games/arknights";
        shortname = "arknights";
        # provisional URL
        installerUrl = "https://launcher-pkg-ark-en.yo-star.com/install_pkg/game_launcher/Arknights_EN/Arknights_EN_Gamelauncher-1.8.1-setup.exe";
        mainBinary = "YostarGames/Arknights_EN/Arknights.exe";
        launcherBinary = "YostarGames/Arknights_EN_Gamelauncher/Arknights_EN_Gamelauncher.exe";
        icon = icons.arknights;
        useUmu = true;
        useGamescope = false; # gamescope causes random game freezing (music still plays but video is frozen in place)
        customProtonPath = compatTool pkgs.unstable.dwproton-bin; # game has no AC issues, can use any version of proton here
      })

      # Arknights: Endfield
      #
      # This game uses ACE, getting it to run requires workarounds.  Just use DWproton, they support the calls required to get everything working.
      (callPackage ../pkgs/wine-game.nix {
        title = "Arknights: Endfield";
        baseDir = "${config.home.homeDirectory}/.local/share/games/endfield";
        shortname = "endfield";
        installerUrl = "https://launcher.gryphline.com/launcher/get_latest_launcher?appcode=TiaytKBUIEdoEwRT&ta=endfield&channel=6&sub_channel=6";
        launcherBinary = "GRYPHLINK/Launcher.exe";
        mainBinary = "direct-launch.exe";
        icon = icons.endfield;
        useUmu = true;
        scriptPre = "${pkgs.writeTextFile {
          name = "ensure-endfield-patches";
          text = ''
            if [ ! -f "~/.local/share/games/endfield/game/direct-launch.exe" ]; then
              cd ~/.local/share/games/endfield/game

              # native cross compile packages on nixos seem broken
              BUILDDIR=$(mktemp -d)
              cd $BUILDDIR
              cp ${inputs.endfield-wine-crossover}/tools/direct-launch.c $BUILDDIR
              ${pkgs.podman}/bin/podman run -it --rm -v $BUILDDIR:/mnt devitllc/mingw-w64 /usr/local/bin/x86_64-w64-mingw32-gcc -O2 -municode -o direct-launch.exe direct-launch.c -luser32 || exit 1
              cp $BUILDDIR/direct-launch.exe ~/.local/share/games/endfield/game/
            fi
          '';
          executable = true;
          destination = "/bin/ensure-endfield-patches";
        }}/bin/ensure-endfield-patches || exit 1";
        # TODO: Autodetect launcher version - probably better done as a direct-launch patch
        gamePostfix = ''--launcher "Z:\home\esi\.local\share\games\endfield\game\GRYPHLINK\1.6.0\Games.exe" --game-dir "Z:\home\esi\.local\share\games\endfield\game\Arknights Endfield"'';
        extraGamescopeFlags = "--force-grab-cursor"; # prevent cursor getting stuck at edge of screen and preventing camera movement
        customProtonPath = compatTool pkgs.unstable.dwproton-bin; # game uses ACE, dwproton recommended
      })

      # LR2oraja
      #
      # Runs natively (written in Java), can have frame stutter issues if the game window isn't kept as the active window.
      # Song management is done through Backbeat; that is installed via AppImage.
      (let ed = inputs.lr2oraja-endlessdream-nix.packages.${system}.lr2oraja-endlessdream.overrideAttrs (final: prev:
        rec {
          gitsrc = fetchFromGitHub {
            owner = "seraxis";
            repo = "lr2oraja-endlessdream";
            rev = "0.4.0";
            hash = "sha256-e9yjO1jbfPKPgozlURP7Sv3ci14T/1sj+1Cl1IYQgsY=";
          };
          installPhase = ''
            runHook preInstall
            mkdir -p $out/opt/lr2oraja-endlessdream
            mkdir -p $out/bin
            ln -s ${prev.startupScript} $out/bin/lr2oraja-endlessdream
            mv * $out/opt/lr2oraja-endlessdream/

            cp ${prev.src} $out/opt/lr2oraja-endlessdream/lr2oraja-endlessdream.jar
            cp -r ${gitsrc}/assets/* "$out/opt/lr2oraja-endlessdream/"
            install -Dm644 ${prev.icon} $out/share/icons/lr2oraja-endlessdream-icon.png

            wrapProgram $out/bin/lr2oraja-endlessdream \
             --set out $out \
             --suffix PATH : "${prev.binPath}" \
             --prefix LD_LIBRARY_PATH : "${pkgs.addDriverRunpath.driverLink}/lib:${prev.libPath}" \
             --prefix XDG_DATA_DIRS : ${pkgs.gtk3}/share/gsettings-schemas/* \

            runHook postInstall
          '';
        });
      in
      (callPackage ../pkgs/native-game.nix {
        title = "LR2oraja";
        baseDir = "${config.home.homeDirectory}/.local/share/lr2oraja-endlessdream";
        shortname = "lr2oraja";
        useGlobalPaths = true;
        launcherBinary = "${ed}/bin/lr2oraja-endlessdream";
        mainBinary = "${ed}/bin/lr2oraja-endlessdream";
        # obs-gamecapture hates injecting into opengl games for some reason, unknown reason
        gamePrefix = "env LD_PRELOAD=$\{LD_PRELOAD\}:${pkgs.unstable.obs-studio-plugins.obs-vkcapture}/lib/obs_glcapture/libobs_glcapture.so";
        gamePostfix = "-s";
        icon = icons.beatoraja;
      }))

      # Girls' Frontline 2: Exilium
      #
      # No issues to report, it just works!  I have had issues with proton 10, but it looks like those issues have been resolved by Proton.
      # The extraLib here is a NixOS issue - proton doesn't properly inject gstreamer dependencies to play the intro video so we have to fix it ourselves.
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
        customProtonPath = compatTool pkgs.unstable.dwproton-bin; # game has no AC issues, can use any version of proton here
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

      # Backbeat - used for song management for LR2oraja
      (
        let
          name = "backbeat";
        in runCommand "${name}" {
          nativeBuildInputs = [ makeWrapper ];
          meta = {
            mainProgram = "${name}";
          };
        }
        ''
          mkdir -p $out/bin
          install -m +x ${inputs.backbeat} $out/bin/${name}

          # appimage-run fails under native wayland
          wrapProgram $out/bin/${name} \
          --add-flag ${pkgs.appimage-run}/bin/appimage-run \
          --prefix GDK_BACKEND : "x11"
        ''
      )
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

    wayland.windowManager.hyprland = {
      extraConfig = lib.mkAfter ''
        hl.on("config.reloaded", function()
          hl.exec_cmd("pidof steam || ${pkgs.uwsm}/bin/uwsm app -- ${pkgs.steam}/bin/steam -silent")
        end)
      '';
    };

    xdg.dataFile = {
      # install LSFG vulkan layer
      lsfg = {
        source = "${pkgs.lsfg-vk}/share/vulkan/implicit_layer.d/VkLayer_LS_frame_generation.json";
        target = "vulkan/implicit_layer.d/VkLayer_LS_frame_generation.json";
      };
    };
  };
}
