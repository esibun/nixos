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
    pathsToLink = ["/share/fish" "/share/qemu"];
    systemPackages = [
      nr
    ];
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
    nix-index-database.comma.enable = true;
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
          ssh
          sudo
        ];
        wantedBy = [];
        script = ''
          cd /etc/nixos
          git fetch
          git reset --hard origin/main
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

  time.timeZone = "America/New_York";
}
