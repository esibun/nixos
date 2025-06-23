{lib, pkgs, inputs, config, ...}:
let
  # simple nixos-rebuild wrapper showing some more details
  nr = pkgs.writeShellScriptBin "nr" ''
    if [ $1 != "boot" ] && [ $1 != "switch" ]; then
      exec ${pkgs.nixos-rebuild}/bin/nixos-rebuild "$@"
    fi
    sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild "$@" 2>&1 | ${pkgs.nix-output-monitor}/bin/nom
    ${pkgs.coreutils-full}/bin/ls -dt /nix/var/nix/profiles/system-* | ${pkgs.coreutils-full}/bin/head -n2 | ${pkgs.coreutils-full}/bin/tac | ${pkgs.findutils}/bin/xargs ${pkgs.nvd}/bin/nvd diff
  '';
in
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    ../hardware-configuration.nix
  ];

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
    systemPackages = [
      nr
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

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
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

  systemd = {
    services = {
      auto-update = {
        path = with pkgs; [
          coreutils-full
          findutils
          git
          nix # nixos-rebuild dependency
          nixos-rebuild
          nvd
          sudo
        ];
        wantedBy = [];
        script = ''
          cd /etc/nixos
          git pull
          # nix-output-monitor causes excessive logging
          nixos-rebuild switch
          ls -dt /nix/var/nix/profiles/system-* | head -n2 | tac | xargs nvd diff
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
      # fix for nixpkgs#180175
      NetworkManager-wait-online = {
        serviceConfig.ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
      };
    };
    timers = {
      auto-update = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "07:00";
          Unit = "auto-update.service";
        };
      };
    };
  };

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
