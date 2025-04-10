{lib, pkgs, inputs, ...}:

let
  secrets = (builtins.fromTOML (builtins.readFile (pkgs.fetchurl {
    urls = [
      "http://unraid:2080/nix-secrets"
      "http://192.168.1.154:2080/nix-secrets"
    ];
    hash = "sha256-lJfhBGki/7EVzWHKy6Q41OeC/Mo7PsDWsL2C/L8a4ac=";
  })));
in
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
      package = pkgs.unstable.mesa;
      package32 = pkgs.unstable.pkgsi686Linux.mesa;
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
        oldDependency = pkgs.mesa;
        newDependency = (pkgs.symlinkJoin rec {
          version = pkgs.unstable.mesa.version;
          name = "mesa-${version}";
          paths = [
            (pkgs.unstable.libgbm.overrideAttrs(prev: {
              version = pkgs.unstable.mesa.version;
              src = pkgs.unstable.mesa.src;
            }))
            # Inject packages split in pkgs.unstable
            # Remove this when upgrading to 25.05
            pkgs.unstable.dri-pkgconfig-stub
            pkgs.unstable.mesa-gl-headers
          ];

          meta = pkgs.unstable.mesa.meta;
        });
      }
    ];
  };

  # fix for nixpkgs#180175
  systemd.services.tailscale.after = [ "systemd-networkd-wait-online.service" ];

  # increase rtkit limits for pipewire
  systemd.services.rtkit-daemon.serviceConfig.ExecStart = [ "" "${pkgs.rtkit}/libexec/rtkit-daemon --scheduling-policy=FIFO --our-realtime-priority=89 --max-realtime-priority=88 --min-nice-level=-19 --rttime-usec-max=2000000 --users-max=100 --processes-per-user-max=1000 --threads-per-user-max=10000 --actions-burst-sec=10 --actions-per-burst-max=1000 --canary-cheep-msec=30000 --canary-watchdog-msec=60000" ];

  time.timeZone = "America/New_York";

  users = {
    mutableUsers = false;
    users.esi = {
      isNormalUser = true;
      extraGroups = lib.mkDefault ["input" "pipewire" "wheel"];
      hashedPassword = secrets.passwords.esi;
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ]; # needed for some gtk apps
    config = {
      sway = { # use GTK implementations except for WLR specific things
        default = [
          "gtk"
        ];
        "org.freedesktop.impl.portal.Screencast" = [
          "wlr"
        ];
        "org.freedesktop.impl.portal.Screenshot" = [
          "wlr"
        ];
      };
    };
  };
}
