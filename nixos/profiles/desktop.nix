{pkgs, config, ...}:

{
  boot = {
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';
  };

  programs = {
    dconf.enable = true; # GTK Settings
    hyprland = {
      enable = true;
      package = pkgs.unstable.hyprland;
      withUWSM = true;
    };
    seahorse.enable = true; # gnome-keyring secrets support
  };

  security = {
    pam.services.hyprlock = {}; # required for hyprlock to work
    # used for PA/PW realtime + gamemode tweaks
    rtkit.enable = true;
  };

  services = {
    blueman.enable = true;
    flatpak.enable = true;
    gnome.gnome-keyring.enable = true;
    libinput.enable = true; # touchpad support
    pipewire = {
      enable = true;
      wireplumber.enable = true;
      audio.enable = true;
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
    };
    udisks2.enable = true; # Nautilus disk management support
  };

  # boot systemd to runlevel 5 instead of 3 (for UWSM)
  systemd.defaultUnit = "graphical.target";

  # increase rtkit limits for pipewire
  systemd.services.rtkit-daemon.serviceConfig.ExecStart = [ "" "${pkgs.rtkit}/libexec/rtkit-daemon --scheduling-policy=FIFO --our-realtime-priority=89 --max-realtime-priority=88 --min-nice-level=-19 --rttime-usec-max=2000000 --users-max=100 --processes-per-user-max=1000 --threads-per-user-max=10000 --actions-burst-sec=10 --actions-per-burst-max=1000 --canary-cheep-msec=30000 --canary-watchdog-msec=60000" ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      # xdg-desktop-portal-hyprland (added by programs.hyprland.enable)
    ]; # needed for some gtk apps
    config = {
      common = { # use GTK implementations except for WLR specific things
        default = [
          "gtk"
        ];
        "org.freedesktop.impl.portal.Screencast" = [
          "hyprland"
        ];
        "org.freedesktop.impl.portal.Screenshot" = [
          "hyprland"
        ];
      };
    };
  };
}
