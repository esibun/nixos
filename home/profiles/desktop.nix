{pkgs, lib, config, inputs, ...}:

let
  custom = {
    hyprlock-dpms = pkgs.writeShellScriptBin "hyprlock-dpms" (builtins.readFile ../../files/scripts/hyprlock-dpms);
  };
  swaybg = pkgs.fetchurl {
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
      # Custom Scripts
      custom.hyprlock-dpms

      # Sway + Supporting Packages
      rofi-wayland
      polkit_gnome # Authentication dialogs
      seatd # fix cursor size
      swayidle
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
      (equibop.overrideAttrs (final: prev: {
        # Use unstable equibop but build against stable deps (don't want to build electron!)
        src = unstable.equibop.src;
        version = unstable.equibop.version;
        pnpmDeps = unstable.equibop.pnpmDeps;
        patches = unstable.equibop.patches ++ [
          vesktop-cam-patch
        ];
        # use stable autoPatchelfHook
        nativeBuildInputs = (lib.lists.remove unstable.autoPatchelfHook unstable.equibop.nativeBuildInputs) ++ [pkgs.autoPatchelfHook];
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
          path = "${swaybg}";
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
        looking-glass-obs
      ];
    };
  };

  services = {
    swaync = {
      enable = true;
      settings = {
        hide-on-action = false;
      };
      style = inputs.catppuccin-swaync-mocha;
    };
  };

  # Autostart for polkit_gnome
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        Wants = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };

  wayland.windowManager.sway = let
    alwaysActiveKeybinds = let
      down = config.wayland.windowManager.sway.config.down;
      left = config.wayland.windowManager.sway.config.left;
      menu = config.wayland.windowManager.sway.config.menu;
      modifier = config.wayland.windowManager.sway.config.modifier;
      right = config.wayland.windowManager.sway.config.right;
      terminal = config.wayland.windowManager.sway.config.terminal;
      up = config.wayland.windowManager.sway.config.up;
    in {
      "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
      "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
      "${modifier}+XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
      "${modifier}+XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-volume @DEFAULT_SOURCE@ +5%";
      "${modifier}+XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-volume @DEFAULT_SOURCE@ -5%";
      "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";

      "${modifier}+c" = "exec 'GRIM_DEFAULT_DIR=$HOME/Pictures ${pkgs.grim}/bin/grim -g \"\$(${pkgs.slurp}/bin/slurp)\"'";

      "${modifier}+Return" = "exec ${terminal}";
      "${modifier}+Shift+q" = "kill";
      "${modifier}+Shift+c" = "reload";

      "${modifier}+${left}" = "focus left";
      "${modifier}+${down}" = "focus down";
      "${modifier}+${up}" = "focus up";
      "${modifier}+${right}" = "focus right";

      "${modifier}+Shift+${left}" = "move left";
      "${modifier}+Shift+${down}" = "move down";
      "${modifier}+Shift+${up}" = "move up";
      "${modifier}+Shift+${right}" = "move right";

      "--inhibited ${modifier}+Control+1" = "workspace number 1";
      "--inhibited ${modifier}+Control+2" = "workspace number 2";
      "--inhibited ${modifier}+Control+3" = "workspace number 3";
      "--inhibited ${modifier}+Control+4" = "workspace number 4";
      "--inhibited ${modifier}+Control+5" = "workspace number 5";
      "--inhibited ${modifier}+Control+6" = "workspace number 6";
      "--inhibited ${modifier}+Control+7" = "workspace number 7";
      "--inhibited ${modifier}+Control+8" = "workspace number 8";
      "--inhibited ${modifier}+Control+9" = "workspace number 9";
      "--inhibited ${modifier}+Control+0" = "workspace number 10";

      "--inhibited ${modifier}+Shift+1" = "move container to workspace number 1; workspace number 1";
      "--inhibited ${modifier}+Shift+2" = "move container to workspace number 2; workspace number 2";
      "--inhibited ${modifier}+Shift+3" = "move container to workspace number 3; workspace number 3";
      "--inhibited ${modifier}+Shift+4" = "move container to workspace number 4; workspace number 4";
      "--inhibited ${modifier}+Shift+5" = "move container to workspace number 5; workspace number 5";
      "--inhibited ${modifier}+Shift+6" = "move container to workspace number 6; workspace number 6";
      "--inhibited ${modifier}+Shift+7" = "move container to workspace number 7; workspace number 7";
      "--inhibited ${modifier}+Shift+8" = "move container to workspace number 8; workspace number 8";
      "--inhibited ${modifier}+Shift+9" = "move container to workspace number 9; workspace number 9";
      "--inhibited ${modifier}+Shift+0" = "move container to workspace number 10; workspace number 10";

      "--inhibited ${modifier}+Control+bracketleft" = "move workspace to output left";
      "--inhibited ${modifier}+Control+bracketright" = "move workspace to output right";

      "${modifier}+Shift+space" = "floating toggle";
      "${modifier}+Control+space" = "focus mode_toggle";
      "${modifier}+Control+Shift+space" = "floating enable; resize set 320 180; move position 0 0";
      "${modifier}+backslash" = "exec ${pkgs.swaynotificationcenter}/bin/swaync-client --toggle-panel";

      "${modifier}+Shift+minus" = "move scratchpad";
      "${modifier}+minus" = "scratchpad show";

    };
  in {
    enable = true;

    extraSessionCommands = ''
      export AMD_VULKAN_ICD=RADV
    '';

    config = {
      bars = [
        { command = "${pkgs.waybar}/bin/waybar"; }
      ];

      menu = "${pkgs.rofi-wayland}/bin/rofi -show drun -drun-match-fields name,generic,categories,keywords";
      modifier = "Mod1";
      terminal = "${pkgs.wezterm}/bin/wezterm";

      # note: we don't want default keybinds, so don't use lib.mkOptionDefault
      keybindings = let
        down = config.wayland.windowManager.sway.config.down;
        left = config.wayland.windowManager.sway.config.left;
        menu = config.wayland.windowManager.sway.config.menu;
        modifier = config.wayland.windowManager.sway.config.modifier;
        right = config.wayland.windowManager.sway.config.right;
        terminal = config.wayland.windowManager.sway.config.terminal;
        up = config.wayland.windowManager.sway.config.up;
      in
      {
        "${modifier}+space" = "exec ${menu}";
        "${modifier}+f" = "fullscreen";
        "${modifier}+x" = "mode system";
        "${modifier}+r" = "mode resize";

        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+0" = "workspace number 10";

        "--inhibited ${modifier}+F11" = "mode gaming";
      } // alwaysActiveKeybinds;
      modes = let
        down = config.wayland.windowManager.sway.config.down;
        left = config.wayland.windowManager.sway.config.left;
        modifier = config.wayland.windowManager.sway.config.modifier;
        right = config.wayland.windowManager.sway.config.right;
        up = config.wayland.windowManager.sway.config.up;
      in
      {
        gaming = {
          "--inhibited ${modifier}+F11" = "mode default";
        } // alwaysActiveKeybinds;
        resize = {
          "${left}" = "resize shrink width 10px";
          "${down}" = "resize grow height 10px";
          "${up}" = "resize shrink height 10px";
          "${right}" = "resize grow width 10px";
          "Shift+${left}" = "resize shrink width 50px";
          "Shift+${down}" = "resize grow height 50px";
          "Shift+${up}" = "resize shrink height 50px";
          "Shift+${right}" = "resize grow width 50px";

          "Return" = "mode default";
          "Escape" = "mode default";
        };
        system = {
          "s" = "exec \"shutdown now\"; mode default";
          "r" = "exec \"reboot\"; mode default";
          "l" = "exec \"hyprlock-dpms\"; mode default";
          "e" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'";
          "Return" = "mode default";
          "Escape" = "mode default";
          "${modifier}+x" = "mode default";
        };
      };

      input = {
        "type:pointer" = {
          accel_profile = "flat";
          pointer_accel = "-0.333";
        };
      };

      output = {
        "*" = {
          bg = "${swaybg} fill";
        };
      };

      gaps = {
        inner = 5;
        smartBorders = "on";
        smartGaps = true;
      };
      seat = {
        "seat0" = {
          xcursor_theme = "capitaine-cursors 64";
        };
      };
      window.border = 1;
      window.titlebar = false;

      startup = [
        { command = "${pkgs.arrpc}/bin/arrpc"; }
        { command = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service"; }
      ];
    };
  };
}
