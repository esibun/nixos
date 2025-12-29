{pkgs, lib, config, inputs, system, ...}:

let
  hyprbg = pkgs.fetchurl {
    url = "https://cdn.donmai.us/original/62/df/__aa_12_and_lind_girls_frontline_and_1_more_drawn_by_yakupan__62dfeb4066ce6bf6c761cea62c5aa0c7.jpg";
    hash = "sha256-MzW/idBeCF3t+CO60G1O74PUkh0CEldXWyY8tB8mH48=";
  };
in
{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  fonts = {
    fontconfig.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Quartz Nord";
      package = (pkgs.callPackage ../pkgs/quartz-nord.nix {});
    };
  };

  home = {
    file = {
      ".config/waybar" = {
        source = ../../files/configs/waybar;
        recursive = true;
      };

      ".config/konapaper/konapaper.conf".source = ../../files/configs/konapaper.conf;
      ".config/rofi/config.rasi".source = "${inputs.rofi-adi1090x}/files/launchers/type-1/style-5.rasi";
      ".config/rofi/shared/colors.rasi".source = ../../files/configs/rofi/shared/colors.rasi;
      ".config/rofi/shared/fonts.rasi".source = "${inputs.rofi-adi1090x}/files/launchers/type-1/shared/fonts.rasi";
      ".config/rofi/colors/nord-light.rasi".source = ../../files/configs/rofi/colors/nord-light.rasi;

      ".wezterm.lua".source = ../../files/configs/wezterm/wezterm.lua;
    };
    packages = with pkgs; [
      # Hyprland + Supporting Packages
      hypridle
      hyprpolkitagent # Authentication dialogs
      rofi
      seatd # fix cursor size
      waybar
      xdg-utils
      inputs.awww.packages.${system}.awww

      # General Dependencies
      libnotify

      # Waybar Dependencies
      jq
      lsof

      # Fonts
      fira-code
      font-awesome_5
      nerd-fonts.symbols-only
      nerd-fonts.ubuntu
      roboto
      source-han-sans
      noto-fonts-color-emoji
      ttf_bitstream_vera # to fix certain emoji
      unifont

      # Browser
      unstable.firefox # follow unstable, Twitch requires it

      # Command Prompt
      wezterm

      # Media
      easyeffects
      mpv

      # Productivity
      onlyoffice-desktopeditors

      # Social Media
      arrpc # equibop dependency
      unstable.equibop

      # Utilities
      file-roller
      font-manager
      gnome-disk-utility
      grim
      nautilus
      pavucontrol
      pulseaudio # for pactl
      slurp
    ];
    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.nordzy-cursor-theme;
      name = "Nordzy-cursors-white";
      size = 48;
    };
  };

  programs = {
    bash = {
      enable = true;
      initExtra = ''
        if ${pkgs.uwsm}/bin/uwsm check may-start 1 &> /dev/null && ${pkgs.uwsm}/bin/uwsm select; then
          exec ${pkgs.uwsm}/bin/uwsm start default
        fi
      '';
    };
    hyprlock = {
      enable = true;
      package = pkgs.unstable.hyprlock;
      settings = {
        background = {
          monitor = "";
          path = "${hyprbg}";
          blur_passes = 3;
          blur_size = 2;
          brightness = 0.3;
        };
        input-field = {
          monitor = "";
          fade_on_empty = false;
          position = "0, -20";
          font_size = 24;
        };
        label = [
          {
            monitor = "";
            text = "esi";
            position = "0, 100";
            font_size = 24;
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "<b>$TIME12</b>";
            position = "0, 300";
            font_size = 48;
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
    obs-studio = {
      enable = true;
      package = pkgs.unstable.obs-studio;
      plugins = with pkgs.unstable.obs-studio-plugins; [
        obs-composite-blur
        obs-pipewire-audio-capture
        obs-vkcapture
        wlrobs
        looking-glass-obs
      ];
    };
  };

  services = {
    flatpak = {
      packages = [
        "app.grayjay.Grayjay"
      ];
      update.onActivation = true;
    };
    hypridle = {
      enable = true;
      settings = {
        listener = [
          {
            timeout = 5;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
    swaync = {
      enable = true;
      settings = {
        hide-on-action = false;
      };
      style = ../../files/configs/swaync/style.css;
    };
  };

  systemd.user = {
    services = {
      # override hypridle autostart (seems no other way to do this)
      hypridle = {
        Install = {
          WantedBy = lib.mkForce [];
        };
      };
      hyprlock-daemon = {
        Unit = {
          Description = "Hyprlock Monitoring Service";
          OnFailure = "hyprlock-recover.service";
        };
        Service = {
          Type = "simple";
          ExecStartPre = "${pkgs.systemd}/bin/systemctl --user start hypridle";
          ExecStart = "${pkgs.hyprlock}/bin/hyprlock";
          ExecStopPost = "${pkgs.systemd}/bin/systemctl --user stop hypridle";
        };
      };
      hyprlock-recover = {
        Unit = {
          Description = "Hyprlock Recovery Script";
        };
        Service = {
          Type = "oneshot";
          ExecStart = [
            "${pkgs.hyprland}/bin/hyprctl --instance 0 keyword 'misc:allow_session_lock_restore 1'"
            "${pkgs.systemd}/bin/systemctl --user restart hypridle"
            "${pkgs.systemd}/bin/systemctl --user restart hyprlock-daemon"
            "${pkgs.coreutils}/bin/sleep 5"
            "${pkgs.hyprland}/bin/hyprctl --instance 0 keyword 'misc:allow_session_lock_restore 0'"
          ];
        };
      };
      wallpaper-rotate = {
        Unit = {
          Description = "Wallpaper Rotator";
        };
        Service = {
          Type = "oneshot";
          ExecStart = [
            "${pkgs.bash}/bin/bash ${inputs.konapaper}/konapaper.sh --rating \"s\""
          ];
        };
      };
    };
    timers = {
      wallpaper-rotate = {
        Unit = {
          Description = "Wallpaper Rotator";
        };
        Timer = {
          OnUnitActiveSec = "2m";
          Unit = "wallpaper-rotate.service";
        };
        Install = {
          WantedBy = [
            "graphical-session.target"
          ];
        };
      };
    };
  };

  wayland.windowManager.hyprland = let
    mod = "ALT";
    terminal = "wezterm";
    left = "H";
    down = "J";
    up = "K";
    right = "L";
    alwaysActiveKeybinds = [
      ", XF86AudioRaiseVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%"
      ", XF86AudioLowerVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%"
      "${mod}, XF86AudioMute, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"
      "${mod}, XF86AudioRaiseVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-source-volume @DEFAULT_SOURCE@ +5%"
      "${mod}, XF86AudioLowerVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-source-volume @DEFAULT_SOURCE@ -5%"
      ", XF86AudioMute, exec, ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle"

      "${mod}, c, exec, GRIM_DEFAULT_DIR=$HOME/Pictures ${pkgs.grim}/bin/grim -g \"\$(${pkgs.slurp}/bin/slurp)\""

      "${mod}, Return, exec, ${terminal}"
      "${mod}_SHIFT, q, killactive"

      "${mod}, ${left}, movefocus, l"
      "${mod}, ${down}, movefocus, d"
      "${mod}, ${up}, movefocus, u"
      "${mod}, ${right}, movefocus, r"

      "${mod}_SHIFT, ${left}, movewindow, l"
      "${mod}_SHIFT, ${down}, movewindow, d"
      "${mod}_SHIFT, ${up}, movewindow, u"
      "${mod}_SHIFT, ${right}, movewindow, r"

      "${mod}_CONTROL, 1, workspace, 1"
      "${mod}_CONTROL, 2, workspace, 2"
      "${mod}_CONTROL, 3, workspace, 3"
      "${mod}_CONTROL, 4, workspace, 4"
      "${mod}_CONTROL, 5, workspace, 5"
      "${mod}_CONTROL, 6, workspace, 6"
      "${mod}_CONTROL, 7, workspace, 7"
      "${mod}_CONTROL, 8, workspace, 8"
      "${mod}_CONTROL, 9, workspace, 9"
      "${mod}_CONTROL, 0, workspace, 10"

      "${mod}_SHIFT, 1, movetoworkspace, 1"
      "${mod}_SHIFT, 2, movetoworkspace, 2"
      "${mod}_SHIFT, 3, movetoworkspace, 3"
      "${mod}_SHIFT, 4, movetoworkspace, 4"
      "${mod}_SHIFT, 5, movetoworkspace, 5"
      "${mod}_SHIFT, 6, movetoworkspace, 6"
      "${mod}_SHIFT, 7, movetoworkspace, 7"
      "${mod}_SHIFT, 8, movetoworkspace, 8"
      "${mod}_SHIFT, 9, movetoworkspace, 9"
      "${mod}_SHIFT, 0, movetoworkspace, 10"

      "${mod}_CONTROL, bracketleft, movecurrentworkspacetomonitor, -1"
      "${mod}_CONTROL, bracketright, movecurrentworkspacetomonitor, +1"

      "${mod}_SHIFT, space, togglefloating"
      #"${mod}_CONTROL, SHIFT+space, floating enable; resize set 320 180; move position 0 0"
      "${mod}, backslash, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client --toggle-panel"

      "${mod}_SHIFT, minus, movetoworkspace, special"
      "${mod}, minus, togglespecialworkspace"
    ];
  in {
    enable = true;
    package = null; # don't install hyprland to user profile (we're using system profile for uwsm)
    settings = {
      animation = [
        "workspaces, 1, 3, default"
      ];
      bind = let
        theme = "${config.home.homeDirectory}/.config/rofi/launchers/type-1/style-5.rasi";
        menu = "${pkgs.rofi}/bin/rofi -show drun -drun-match-fields name,generic,categories,keywords -run-command \"uwsm app -- {cmd}\"";
      in [
        "${mod}, space, exec, ${menu}"
        "${mod}, f, fullscreen, 0"
        "${mod}, x, submap, system"
        "${mod}, r, submap, resize"

        "${mod}, 1, workspace, 1"
        "${mod}, 2, workspace, 2"
        "${mod}, 3, workspace, 3"
        "${mod}, 4, workspace, 4"
        "${mod}, 5, workspace, 5"
        "${mod}, 6, workspace, 6"
        "${mod}, 7, workspace, 7"
        "${mod}, 8, workspace, 8"
        "${mod}, 9, workspace, 9"
        "${mod}, 0, workspace, 10"

        "${mod}, F11, submap, gaming"
      ];
      bindl = alwaysActiveKeybinds;
      bindm = [
        "${mod}, mouse:272, movewindow"
      ];
      exec = [
        # no better way to do this sadly; HM systemd unit management is kinda bad
        "systemctl --user restart hyprpaper"
        "systemctl --user restart hyprpolkitagent"
        "systemctl --user restart waybar"
      ];
      exec-once = let
        awww = inputs.awww.packages.${system}.awww;
      in [
        "${awww}/bin/awww-daemon"
        "${pkgs.uwsm}/bin/uwsm app -- ${pkgs.arrpc}/bin/arrpc"
        "${pkgs.uwsm}/bin/uwsm app -- ${pkgs.easyeffects}/bin/easyeffects --gapplication-service"
        # config files don't seem to actually read
        "${pkgs.hyprland}/bin/hyprctl setcursor Nordzy-cursors-white 48"
      ];
      general = {
        gaps_out = 5;
      };
      workspace = [
        # smart gaps rules
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
      ];
      windowrulev2 = [
        # smart gaps rules
        "bordersize 0, floating:0, onworkspace:w[tv1]"
        "rounding 0, floating:0, onworkspace:w[tv1]"
        "bordersize 0, floating:0, onworkspace:f[1]"
        "rounding 0, floating:0, onworkspace:f[1]"
      ];
      # broken, see hyprwm/Hyprland#10278
      #xwayland = {
      #  force_zero_scaling = true;
      #};
    };
    systemd.enable = false; # conflicts with uwsm
    extraConfig = let
      submapPre = ''
        submap = @SUBMAP@
      '';
      submapPost = ''
        submap = reset
      '';
      submaps = {
        gaming = [
          "bindl = ${mod}, F11, submap, reset"
        ] ++ (builtins.map (bind: "bindl = " + bind) alwaysActiveKeybinds);
        resize = [
          "bind = , ${left}, resizeactive, -10 0"
          "bind = , ${down}, resizeactive, 0 10"
          "bind = , ${up}, resizeactive, 0 -10"
          "bind = , ${right}, resizeactive, 10 0"
          "bind = SHIFT, ${left}, resizeactive, -50 0"
          "bind = SHIFT, ${down}, resizeactive, 0 50"
          "bind = SHIFT, ${up}, resizeactive, 0 -50"
          "bind = SHIFT, ${right}, resizeactive, 50 0"
          "bind = , escape, submap, reset"
        ];
        system = [
          "bind = , s, exec, shutdown now"
          "bind = , s, submap, reset"
          "bind = , r, exec, reboot"
          "bind = , r, submap, reset"
          "bind = , l, exec, ${pkgs.systemd}/bin/systemctl --user start hyprlock-daemon"
          "bind = , l, submap, reset"
          "bind = , e , exec, ${pkgs.sway}/bin/swaynag -b \"OK\" \"uwsm stop\" -s \"Cancel\" -t warning -m \"End your hyprland session?\"" 
          "bind = , e, submap, reset"
          "bind = , escape, submap, reset"
        ];
      };
      # concatenate the calculated submap strings together
    in (lib.concatStrings (builtins.attrValues (
      (builtins.mapAttrs (mapName: mapBinds:
        # prefix submap with pre-text
        (builtins.replaceStrings ["@SUBMAP@"] [mapName] submapPre) +
        # add newlines to each submap value and concatenate
        (lib.concatStrings (builtins.map (line: line + "\n") mapBinds)) +
        # add escape as submap reset key and finish submap binding text
        submapPost) submaps))
      )
    );
  };
}
