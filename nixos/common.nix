{lib, pkgs, inputs, config, ...}:

{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    ../hardware-configuration.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot = {
    kernel.sysctl = {
      "kernel.printk" = "2 4 1 7"; # hide debug spew on command line
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "preempt=full"
      "split_lock_detect=off"
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  environment = {
    pathsToLink = ["/share/fish" "/share/qemu"];
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  networking = {
    networkmanager.enable = true;
  };

  programs = {
    dconf.enable = true;
    nix-index-database.comma.enable = true;
    seahorse.enable = true; # gnome-keyring secrets support
  };

  security = {
    polkit.enable = true;
    pam.services.hyprlock = {}; # required for hyprlock to work
  };

  services = {
    blueman.enable = true;
    dbus.enable = true;
    gnome.gnome-keyring.enable = true;
    libinput.enable = true; # touchpad support
    openssh = {
      enable = true;
      openFirewall = false;
      ports = [ 2222 ];
    };
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
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };
    udisks2.enable = true; # Nautilus disk management support
  };

  system = {
    replaceDependencies.replacements = [
      {
        oldDependency = pkgs.unstable.libgbm;
        newDependency = pkgs.libgbm;
      }
    ];
  };

  # fix for nixpkgs#180175
  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];

  # increase rtkit limits for pipewire
  systemd.services.rtkit-daemon.serviceConfig.ExecStart = [ "" "${pkgs.rtkit}/libexec/rtkit-daemon --scheduling-policy=FIFO --our-realtime-priority=89 --max-realtime-priority=88 --min-nice-level=-19 --rttime-usec-max=2000000 --users-max=100 --processes-per-user-max=1000 --threads-per-user-max=10000 --actions-burst-sec=10 --actions-per-burst-max=1000 --canary-cheep-msec=30000 --canary-watchdog-msec=60000" ];

  time.timeZone = "America/New_York";

  users = {
    mutableUsers = false;
    users.esi = {
      isNormalUser = true;
      extraGroups = lib.mkDefault ["input" "pipewire" "video" "wheel"];
      hashedPasswordFile = config.age.secrets.esi-passwordfile.path;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-hyprland
    ]; # needed for some gtk apps
    config = {
      sway = { # use GTK implementations except for WLR specific things
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
