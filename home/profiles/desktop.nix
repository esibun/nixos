{pkgs, lib, config, inputs, ...}:

let
  hyprbg = pkgs.fetchurl {
    url = "https://cdn.donmai.us/original/47/8e/__hk416_ump45_ump9_g11_and_dinergate_girls_frontline_drawn_by_juna__478e9a2cd54a04d003d2610a77da4556.jpg";
    hash = "sha256-nmXCeTkL7nRJSnmFaH581S+gxIy817WQl1aG9BmHv/Y=";
  };
  vesktop-cam-patch = pkgs.fetchpatch {
    # Pull PR: Allow streaming from camera devices
    #  There's some interest in upstreaming but the PR itself is a year old.
    url = "https://patch-diff.githubusercontent.com/raw/Vencord/Vesktop/pull/195.patch";
    hash = "sha256-0SZ31rLAVu219ZBya9OmZLaylGr4gfd6wIw9wwLtBBQ=";
  };
in
{
  home = {
    file = {
      ".config/rofi" = {
        source = ../../files/configs/rofi;
        recursive = true;
      };
      ".config/waybar" = {
        source = ../../files/configs/waybar;
        recursive = true;
      };
      ".wezterm.lua".source = ../../files/configs/wezterm/wezterm.lua;

      ".local/share/rofi/themes/catppuccin-mocha.rasi".source = ../../files/rofi/catppuccin-mocha.rasi;
    };
    packages = with pkgs; [
      # Hyprland + Supporting Packages
      hypridle
      hyprpolkitagent # Authentication dialogs
      rofi-wayland
      seatd # fix cursor size
      waybar
      xdg-utils

      # General Dependencies
      libnotify

      # Waybar Dependencies
      jq
      lsof

      # Fonts
      fira-code
      font-awesome_5
      (nerdfonts.override {
        fonts = [
          "NerdFontsSymbolsOnly"
          "Ubuntu"
        ];
      })
      roboto
      source-han-sans-japanese
      source-han-sans-korean
      noto-fonts-color-emoji
      ttf_bitstream_vera # to fix certain emoji

      # Other Look & Feel
      capitaine-cursors

      # Browser
      unstable.firefox # follow unstable, Twitch requires it

      # Command Prompt
      wezterm

      # Media
      easyeffects
      mpv

      # Productivity
      onlyoffice-bin

      # Social Media
      arrpc # equibop dependency
      (unstable.equibop.overrideAttrs (final: prev: {
        patches = unstable.equibop.patches ++ [
          vesktop-cam-patch
        ];
      }))

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
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      size = 64;
    };
  };

  programs = {
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
        obs-vkcapture # enabled for now; see nixpkgs#349053 if it breaks build
        wlrobs
        (looking-glass-obs.overrideAttrs(final: prev: {
          nativeBuildInputs = prev.nativeBuildInputs ++ [
            pkgs.unstable.libGL
          ];
        }))
      ];
    };
  };

  services = {
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
    hyprpaper  = {
      enable = true;
      settings = {
        preload = [
          "${hyprbg}"
        ];

        wallpaper = [
          ",${hyprbg}"
        ];
      };
    };
    swaync = {
      enable = true;
      settings = {
        hide-on-action = false;
      };
      style = inputs.catppuccin-swaync-mocha;
    };
  };

  systemd.user.services = {
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
    package = pkgs.unstable.hyprland;
    settings = {
      animation = [
        "workspaces, 1, 3, default"
      ];
      bind = let
        menu = "${pkgs.rofi-wayland}/bin/rofi -show drun -drun-match-fields name,generic,categories,keywords";
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
      exec = [
        # no better way to do this sadly; HM systemd unit management is kinda bad
        "systemctl --user restart hyprpaper"
        "systemctl --user restart hyprpolkitagent"
        "systemctl --user restart waybar"
      ];
      exec-once = [
        "${pkgs.arrpc}/bin/arrpc"
        "${pkgs.easyeffects}/bin/easyeffects --gapplication-service"
      ];
      general = {
        gaps_out = 5;
      };
      input = {
        sensitivity = -0.333;
        accel_profile = "flat";
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
          "bind = , s, submap, reset"
          "bind = , l, exec, ${pkgs.systemd}/bin/systemctl --user start hyprlock-daemon"
          "bind = , l, submap, reset"
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
