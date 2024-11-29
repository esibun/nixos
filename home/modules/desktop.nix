{pkgs, ...}:

let
  custom = {
    swaylock-dpms = pkgs.writeShellScriptBin "swaylock-dpms" (builtins.readFile ../../files/scripts/swaylock-dpms);
  };
in
{
  home = {
    file = {
      ".config/rofi" = {
        source = ../../files/configs/rofi;
        recursive = true;
      };
      ".config/sway" = {
        source = ../../files/configs/sway;
        recursive = true;
      };
      ".config/waybar" = {
        source = ../../files/configs/waybar;
        recursive = true;
      };
      ".config/dunst/dunstrc".source = ../../files/configs/dunst/dunstrc;
      ".wezterm.lua".source = ../../files/configs/wezterm/wezterm.lua;

      ".local/share/rofi/themes/catppuccin-mocha.rasi".source = ../../files/rofi/catppuccin-mocha.rasi;
    };
    packages = with pkgs; [
      # Custom Scripts
      custom.swaylock-dpms

      # Sway + Supporting Packages
      dunst
      rofi-wayland
      polkit_gnome # Authentication dialogs
      seatd # fix cursor size
      sway
      swayidle
      swaylock
      waybar
      xdg-utils

      # Waybar Dependencies
      jq
      lsof

      # Fonts
      fira-code
      font-awesome_5
      (nerdfonts.override {
        fonts = [
          "NerdFontsSymbolsOnly"
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
      (unstable.vivaldi.override {
        fontconfig = pkgs.fontconfig;
        mesa = pkgs.mesa;
      }) # follow unstable, Twitch requires it

      # Command Prompt
      wezterm

      # Media
      easyeffects
      mpv

      # Productivity
      onlyoffice-bin

      # Social Media
      (vesktop.overrideAttrs (final: prev: {
        # Use unstable vesktop but build against stable deps (don't want to build electron!)
        src = unstable.vesktop.src;
        version = unstable.vesktop.version;
        pnpmDeps = unstable.vesktop.pnpmDeps;
        patches = unstable.vesktop.patches;
        # use stable autoPatchelfHook
        nativeBuildInputs = (lib.lists.remove unstable.autoPatchelfHook unstable.vesktop.nativeBuildInputs) ++ [pkgs.autoPatchelfHook];
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

  programs.obs-studio = {
    enable = true;
    package = pkgs.unstable.obs-studio;
    plugins = with pkgs.unstable.obs-studio-plugins; [
      obs-composite-blur
      obs-vkcapture # enabled for now; see nixpkgs#349053 if it breaks build
      wlrobs
    ];
  };

  # Autostart for polkit_gnome
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        WantedBy = ["graphical-session.target"];
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
    };
  };
}
