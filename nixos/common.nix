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
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  environment = {
    pathsToLink = ["/share/fish"];
    systemPackages = with pkgs; [
      vim
    ];
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
    nix-index-database.comma.enable = true;
    seahorse.enable = true; # gnome-keyring secrets support
  };

  security = {
    polkit.enable = true;
    pam.services.hyprlock = {}; # required for hyprlock to work
    pki.certificateFiles = [
      ../files/pvpn-twitch.crt
    ];
  };

  services = {
    blueman.enable = true;
    dbus = {
      enable = true;
      implementation = "broker";
    };
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
    autoUpgrade = {
      enable = true;
      dates = "*-*-* 06:00:00";
    };
  };

  # fix for nixpkgs#180175
  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];

  time.timeZone = "America/New_York";

  users = {
    mutableUsers = false;
    users.esi = {
      isNormalUser = true;
      extraGroups = lib.mkDefault ["input" "wheel"];
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
