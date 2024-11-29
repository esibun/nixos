{lib, pkgs, ...}:

let
  secrets = import ../secrets.nix;
in
{
  imports = [
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
    firewall.enable = false; # todo: probably want this on long term
    networkmanager.enable = true;
  };

  programs = {
    seahorse.enable = true; # gnome-keyring secrets support
  };

  security = {
    polkit.enable = true;
    pam.services.swaylock = {}; # required for swaylock to work
    pki.certificateFiles = [
      ../files/pvpn-twitch.crt
    ];
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
    resolved = {
      enable = true;
      domains = ["~."];
      fallbackDns = [""]; # disable fallback
      dnsovertls = "true";
      llmnr = "false"; # LLMNR breaks tailscale name resolution
      extraConfig = ''
        ResolveUnicastSingleLabel=yes
      ''; # allow NextDNS to resolve unicast names
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
      flags = ["--upgrade-all"];
      dates = "*-*-* 06:00:00";
    };
    stateVersion = "23.11";
  };

  # fix for nixpkgs#180175
  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];

  time.timeZone = "America/New_York";

  users = {
    mutableUsers = false;
    users.esi = {
      isNormalUser = true;
      extraGroups = lib.mkDefault ["input" "wheel"];
      hashedPassword = secrets.esi-password;
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
