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

  gtk = let
    quartz-nord = {
      name = "Quartz Nord";
      package = (pkgs.callPackage ../pkgs/quartz-nord.nix {});
    };
  in {
    enable = true;
    theme = quartz-nord;
    gtk4.theme = quartz-nord;
  };

  home = {
    file = {
      ".config/waybar" = {
        source = ../../files/configs/waybar;
        recursive = true;
      };

      ".config/boorupaper/boorupaper.conf".source = ../../files/configs/boorupaper.conf;
      ".config/rofi/config.rasi".source = "${inputs.rofi-adi1090x}/files/launchers/type-1/style-5.rasi";
      ".config/rofi/shared/colors.rasi".source = ../../files/configs/rofi/shared/colors.rasi;
      ".config/rofi/shared/fonts.rasi".source = "${inputs.rofi-adi1090x}/files/launchers/type-1/shared/fonts.rasi";
      ".config/rofi/colors/nord-light.rasi".source = ../../files/configs/rofi/colors/nord-light.rasi;

      ".wezterm.lua".source = ../../files/configs/wezterm/wezterm.lua;
    };
    packages = with pkgs; [
      # Hyprland + Supporting Packages
      hypridle
      hyprpaper
      hyprpolkitagent # Authentication dialogs
      rofi
      seatd # fix cursor size
      ((waybar.overrideAttrs (final: prev: {
        # pull in commit fixing hyprland lua (no release available yet)
        src = pkgs.fetchFromGitHub {
          owner = "Alexays";
          repo = "Waybar";
          rev = "05945748dccce28bf96d26d8f64a9e69a8dd49ba";
          hash = "sha256-51R3mIt8cLNvh/X5qe9vOqeJCj0U9KRyemVE5y+OhiU=";
        };
      })).override {
        # requires way more overriding for something I'm not using
        cavaSupport = false;
      })
      xdg-utils

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
      open-in-mpv

      # Productivity
      onlyoffice-desktopeditors
      wpsoffice

      # Social Media
      arrpc # equibop dependency
      (unstable.equibop.overrideAttrs (final: prev: {
        patches = unstable.equibop.patches ++ [
          ../../files/equibop-cam-patch.patch
        ];
      }))

      # Utilities
      file-roller
      font-manager
      freecad
      gnome-disk-utility
      grim
      nautilus
      orca-slicer # unstable broken atm, see nixpkgs#513195
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
    fish = {
      shellInit = ''
        function boorupaper
          nix-shell -p curl flock jq libxml2 bash coreutils findutils gawk --command "bash ${inputs.boorupaper}/boorupaper.sh $argv"
        end
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
            on-timeout = ''hyprctl dispatch 'hl.dsp.dpms({action="off"})' '';
            on-resume = ''hyprctl dispatch 'hl.dsp.dpms({action="on"})' '';
          }
        ];
      };
    };
    hyprpaper = {
      enable = true;
      settings = {
        splash = false;
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
            ''${pkgs.hyprland}/bin/hyprctl --instance 0 eval 'hl.config({misc = {allow_session_lock_restore = 1}})' ''
            "${pkgs.systemd}/bin/systemctl --user restart hypridle"
            "${pkgs.systemd}/bin/systemctl --user restart hyprlock-daemon"
            "${pkgs.coreutils}/bin/sleep 5"
            ''${pkgs.hyprland}/bin/hyprctl --instance 0 eval 'hl.config({misc = {allow_session_lock_restore = 0}})' ''
          ];
        };
      };
      wallpaper-rotate = {
        Unit = {
          Description = "Wallpaper Rotator";
        };
        Service = {
          Type = "forking";
          Environment = "PATH=${lib.makeBinPath [
            pkgs.curl
            pkgs.flock
            pkgs.jq
            pkgs.libxml2

            # dependencies not listed in readme
            pkgs.hyprpaper
            pkgs.hyprland # for hyprctl
            pkgs.bash # bash (lib/display.sh to set image)
            pkgs.coreutils # dirname
            pkgs.findutils # find
            pkgs.gawk # awk
          ]}";
          ExecStartPre = [
            # Don't run if hyprlock is running
            "${pkgs.bash}/bin/bash -c '! ${pkgs.procps}/bin/pgrep hyprlock'"
            # Don't run if gamemode is on (latency)
            "${pkgs.bash}/bin/bash -c '${pkgs.gamemode}/bin/gamemodelist | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs ${pkgs.coreutils}/bin/test 0 -eq'"
          ];
          ExecStart = [
            "${pkgs.bash}/bin/bash ${inputs.boorupaper}/boorupaper.sh"
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
    # function helpers because honestly the nix -> lua syntax is really ass
    # keybind { key = "key to bind"; func = (see below); flags = (passed unchanged) }
    keybind = x: {
      _args = [
        x.key
      ]
      # func is a string e.g. "dsp.focus"
      #  translates to hl.bind("key", (dsp.focus())
      ++ (lib.optional (builtins.isString x.func) (
        lib.mkLuaInline ("hl." + x.func)
      ))
      # func = list, first elem is call, second elem is args e.g. "dsp.window.move(workspace = 1)"
      #  translates to hl.bind("key", dsp.window.move(workspace = 1))
      #  NOTE: use double single quotes for escaping, i.e. ''arg = "string"''
      #  TODO: write something to properly interpret sets into arguments (lib.generators.toLua doesn't
      #   for this since it doesn't insert commas)
      ++ (lib.optional (builtins.isList x.func) (
        lib.mkLuaInline ("hl." + x.func)
      ))
      # pass flags as-is if defined
      ++ (lib.optional (builtins.hasAttr "flags" x) x.flags);
    };
    # defined without keybind func so the set can be modified in-function
    alwaysActiveKeybinds = [
      { key = "XF86AudioRaiseVolume"; func = ''dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%")''; }
      { key = "XF86AudioLowerVolume"; func = ''dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%")''; }
      { key = "${mod} + XF86AudioMute"; func = ''dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle")''; }
      { key = "${mod} + XF86AudioRaiseVolume"; func = ''dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-source-volume @DEFAULT_SOURCE@ +5%")''; }
      { key = "${mod} + XF86AudioLowerVolume"; func = ''dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-source-volume @DEFAULT_SOURCE@ -5%")''; }
      { key = "XF86AudioMute"; func = ''dsp.exec_cmd("${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle")''; }

      { key = "${mod} + c"; func = ''dsp.exec_cmd("GRIM_DEFAULT_DIR=$HOME/Pictures ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\"")''; }

      { key = "${mod} + Return"; func = ''dsp.exec_cmd("${terminal}")''; }
      { key = "${mod} + SHIFT + q"; func = ''dsp.window.close()''; }

      { key = "${mod} + ${left}"; func = ''dsp.focus({direction = "l"})''; }
      { key = "${mod} + ${down}"; func = ''dsp.focus({direction = "d"})''; }
      { key = "${mod} + ${up}"; func = ''dsp.focus({direction = "u"})''; }
      { key = "${mod} + ${right}"; func = ''dsp.focus({direction = "r"})''; }

      { key = "${mod} + SHIFT + ${left}"; func = ''dsp.window.move({direction = "l"})''; }
      { key = "${mod} + SHIFT + ${down}"; func = ''dsp.window.move({direction = "d"})''; }
      { key = "${mod} + SHIFT + ${up}"; func = ''dsp.window.move({direction = "u"})''; }
      { key = "${mod} + SHIFT + ${right}"; func = ''dsp.window.move({direction = "r"})''; }

      { key = "${mod} + CONTROL + 1"; func = ''dsp.focus({workspace = 1})''; }
      { key = "${mod} + CONTROL + 2"; func = ''dsp.focus({workspace = 2})''; }
      { key = "${mod} + CONTROL + 3"; func = ''dsp.focus({workspace = 3})''; }
      { key = "${mod} + CONTROL + 4"; func = ''dsp.focus({workspace = 4})''; }
      { key = "${mod} + CONTROL + 5"; func = ''dsp.focus({workspace = 5})''; }
      { key = "${mod} + CONTROL + 6"; func = ''dsp.focus({workspace = 6})''; }
      { key = "${mod} + CONTROL + 7"; func = ''dsp.focus({workspace = 7})''; }
      { key = "${mod} + CONTROL + 8"; func = ''dsp.focus({workspace = 8})''; }
      { key = "${mod} + CONTROL + 9"; func = ''dsp.focus({workspace = 9})''; }
      { key = "${mod} + CONTROL + 0"; func = ''dsp.focus({workspace = 10})''; }

      { key = "${mod} + SHIFT + 1"; func = ''dsp.window.move({workspace = 1})''; }
      { key = "${mod} + SHIFT + 2"; func = ''dsp.window.move({workspace = 2})''; }
      { key = "${mod} + SHIFT + 3"; func = ''dsp.window.move({workspace = 3})''; }
      { key = "${mod} + SHIFT + 4"; func = ''dsp.window.move({workspace = 4})''; }
      { key = "${mod} + SHIFT + 5"; func = ''dsp.window.move({workspace = 5})''; }
      { key = "${mod} + SHIFT + 6"; func = ''dsp.window.move({workspace = 6})''; }
      { key = "${mod} + SHIFT + 7"; func = ''dsp.window.move({workspace = 7})''; }
      { key = "${mod} + SHIFT + 8"; func = ''dsp.window.move({workspace = 8})''; }
      { key = "${mod} + SHIFT + 9"; func = ''dsp.window.move({workspace = 9})''; }
      { key = "${mod} + SHIFT + 0"; func = ''dsp.window.move({workspace = 10})''; }

      { key = "${mod} + CONTROL + bracketleft"; func = ''dsp.workspace.move({monitor = "-1"})''; }
      { key = "${mod} + CONTROL + bracketright"; func = ''dsp.workspace.move({monitor = "+1"})''; }

      { key = "${mod} + SHIFT + space"; func = ''dsp.window.float()''; }
      { key = "${mod} + backslash"; func = ''dsp.exec_cmd("${pkgs.swaynotificationcenter}/bin/swaync-client --toggle-panel")''; }

      { key = "${mod} + SHIFT + minus"; func = ''dsp.window.move({workspace = "special"})''; }
      { key = "${mod} + minus"; func = ''dsp.workspace.toggle_special()''; }
    ];
  in {
    enable = true;
    package = null; # don't install hyprland to user profile (we're using system profile for uwsm)
    configType = "lua";
    # hl.on() doesn't seem to be natively supported by hyprland nix config
    # TODO: can make this a bit more elegant
    extraConfig = ''
      hl.on("hyprland.start", function()
        hl.dsp.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- ${pkgs.arrpc}/bin/arrpc")
        hl.dsp.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- ${pkgs.easyeffects}/bin/easyeffects --gapplication-service")
        -- config files don't seem to actually read
        hl.dsp.exec_cmd("${pkgs.hyprland}/bin/hyprctl setcursor Nordzy-cursors-white 48")
      end)
      hl.on("config.reloaded", function()
        hl.dsp.exec_cmd("systemctl --user restart hyprpaper && systemctl --user start wallpaper-rotate")
        hl.dsp.exec_cmd("systemctl --user restart hyprpolkitagent")
        hl.dsp.exec_cmd("systemctl --user restart waybar")
      end)
    '';
    submaps = {
      gaming.settings.bind = [
        (keybind { key = "${mod} + F11"; func = ''dsp.submap("reset")''; flags = { locked = true; }; })
      ] ++ (map (x: keybind (x // { flags = { locked = true; }; } )) alwaysActiveKeybinds);
      resize.settings.bind = [
        (keybind { key = "${left}"; func = ''dsp.window.resize({x = -10, y = 0, relative = true})''; })
        (keybind { key = "${down}"; func = ''dsp.window.resize({x = 0, y = 10, relative = true})''; })
        (keybind { key = "${up}"; func = ''dsp.window.resize({x = 0, y = -10, relative = true})''; })
        (keybind { key = "${right}"; func = ''dsp.window.resize({x = 10, y = 0, relative = true})''; })
        (keybind { key = "SHIFT + ${left}"; func = ''dsp.window.resize({x = -50, y = 0, relative = true})''; })
        (keybind { key = "SHIFT + ${down}"; func = ''dsp.window.resize({x = 0, y = 50, relative = true})''; })
        (keybind { key = "SHIFT + ${up}"; func = ''dsp.window.resize({x = 0, y = -50, relative = true})''; })
        (keybind { key = "SHIFT + ${right}"; func = ''dsp.window.resize({x = 50, y = 0, relative = true})''; })
        (keybind { key = "escape"; func = ''dsp.submap("reset")''; })
      ];
      system = {
        onDispatch = "reset";
        settings = {
          bind = [
            (keybind { key = "s"; func = ''dsp.exec_cmd("${pkgs.hyprshutdown}/bin/hyprshutdown -p \"shutdown now\"")''; })
            (keybind { key = "r"; func = ''dsp.exec_cmd("${pkgs.hyprshutdown}/bin/hyprshutdown -t \"Rebooting...\" -p reboot")''; })
            (keybind { key = "l"; func = ''dsp.exec_cmd("${pkgs.systemd}/bin/systemctl --user start hyprlock-daemon")''; })
            (keybind { key = "e "; func = ''dsp.exec_cmd("${pkgs.sway}/bin/swaynag -b \"OK\" \"${pkgs.hyprshutdown}/bin/hyprshutdown -t \\\"Logging out...\\\"\" -s \"Cancel\" -t warning -m \"End your hyprland session?\"")''; })
            (keybind { key = "escape"; func = ''dsp.submap("reset")''; })
          ];
        };
      };
    };
    settings = {
      config = {
        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
        general = {
          gaps_out = 5;
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };
        # broken, see hyprwm/Hyprland#10278
        #xwayland = {
        #  force_zero_scaling = true;
        #};
      };
      animation = [
        {
          leaf = "workspaces";
          enabled = true;
          speed = 3;
          bezier = "default";
        }
      ];
      bind = let
        theme = "${config.home.homeDirectory}/.config/rofi/launchers/type-1/style-5.rasi";
        menu = ''${pkgs.rofi}/bin/rofi -show drun -drun-match-fields name,generic,categories,keywords -run-command \"uwsm app -- {cmd}\"'';
      in [
        (keybind { key = "${mod} + space"; func = ''dsp.exec_cmd("${menu}")''; })
        (keybind { key = "${mod} + f"; func = ''dsp.window.fullscreen()''; })
        (keybind { key = "${mod} + x"; func = ''dsp.submap("system")''; })
        (keybind { key = "${mod} + r"; func = ''dsp.submap("resize")''; })

        (keybind { key = "${mod} + 1"; func = ''dsp.focus({workspace = 1})''; })
        (keybind { key = "${mod} + 2"; func = ''dsp.focus({workspace = 2})''; })
        (keybind { key = "${mod} + 3"; func = ''dsp.focus({workspace = 3})''; })
        (keybind { key = "${mod} + 4"; func = ''dsp.focus({workspace = 4})''; })
        (keybind { key = "${mod} + 5"; func = ''dsp.focus({workspace = 5})''; })
        (keybind { key = "${mod} + 6"; func = ''dsp.focus({workspace = 6})''; })
        (keybind { key = "${mod} + 7"; func = ''dsp.focus({workspace = 7})''; })
        (keybind { key = "${mod} + 8"; func = ''dsp.focus({workspace = 8})''; })
        (keybind { key = "${mod} + 9"; func = ''dsp.focus({workspace = 9})''; })
        (keybind { key = "${mod} + 0"; func = ''dsp.focus({workspace = 10})''; })

        (keybind { key = "${mod} + F11"; func = ''dsp.submap("gaming")''; })

        (keybind { key = "${mod} + mouse:272"; func = ''dsp.window.drag()''; flags = "mouse"; })
      ] ++ (map (x: keybind (x // { flags = { locked = true; }; } )) alwaysActiveKeybinds);
      workspace_rule = [
        # smart gaps rules
        {
          workspace = "w[tv1]";
          gaps_out = 0;
          gaps_in = 0;
        }
        {
          workspace = "f[1]";
          gaps_out = 0;
          gaps_in = 0;
        }
      ];
      window_rule = [
        # smart gaps rules
        {
          match = {
            float = false;
            workspace = "w[tv1]";
          };
          border_size = 0;
        }
        {
          match = {
            float = false;
            workspace = "w[tv1]";
          };
          rounding = 0;
        }
        {
          match = {
            float = false;
            workspace = "f[1]";
          };
          border_size = 0;
        }
        {
          match = {
            float = false;
            workspace = "f[1]";
          };
          rounding = 0;
        }
        # center all floating windows
        {
          match = {
            float = true;
          };
          center = true;
        }
      ];
    };
    systemd.enable = false; # conflicts with uwsm
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      # xdg-desktop-portal-hyprland (added by hyprland module)
    ];
    config = {
      common = {
        default = [
          # prefer XDPH implementations
          "hyprland"
          "gtk"
        ];
      };
    };
  };
}
