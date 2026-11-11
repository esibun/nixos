{lib, pkgs, inputs, config, ...}:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  boot = {
    kernel.sysctl = {
      "kernel.printk" = "2 4 1 7"; # hide debug spew on command line
    };
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
    pathsToLink = ["/share/fish"];
  };

  networking = {
    networkmanager.enable = true;
  };

  nix = {
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [
        "root"
        "nixbuilder"
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  programs = {
    nix-index-database.comma.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        (pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
        (pkgs.runCommand "appimgrun-lib" {} "mkdir $out; ln -s ${pkgs.appimage-run.fhsenv}/usr/lib64 $out/lib")
        glew # for xsanity (TODO: can we move this to a wrapper?)
      ];
    };
  };

  security = {
    polkit.enable = true;
  };

  services = {
    dbus.enable = true;
    openssh = {
      enable = true;
      openFirewall = false;
      ports = [ 2222 ];
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };
    udev.packages = [
      # allow permission to write to certain usb devices (keyboard updaters, etc.)
      # see systemd#39206 - files >= 73-* don't process uaccess correctly
      (pkgs.writeTextFile {
        name = "72-global-uaccess.rules";
        # Note: Don't set permissions on block or input devices for security reasons, see
        #  https://wiki.archlinux.org/title/Udev
        text = ''
          SUBSYSTEMS=="usb", SUBSYSTEM!="input", SUBSYSTEM!="block", MODE="0660", TAG+="uaccess"
        '';
        destination = "/lib/udev/rules.d/72-global-uaccess.rules";
        checkPhase = ''
          ${pkgs.systemd}/bin/udevadm verify $out/lib/udev/rules.d/72-global-uaccess.rules
        '';
      })
    ];
  };

  systemd = {
    services = {
      auto-update = {
        path = with pkgs; [
          coreutils-full
          findutils
          git
          nh
          nix # nh dependency
          openssh
          sudo
        ];
        wantedBy = [];
        script = ''
          cd /etc/nixos
          git fetch
          git reset --hard origin/main
          NH_ELEVATION_STRATEGY=none nh os switch
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

  time.timeZone = "America/New_York";
}
