# esi-phone is special; we don't use common (yet) since there's a bunch of
# x86-64/desktop environment stuff in there.
#
# Later, all of the desktop boot stuff should be moved into it's own profile.

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
    # Note: nixos-avf takes care of all the hardware configuration stuff
    # ../../hardware-configuration.nix
  ];

  boot = {
    kernel.sysctl = {
      "kernel.printk" = "2 4 1 7"; # hide debug spew on command line
    };
    kernelParams = [
      "preempt=full"
      "split_lock_detect=off"
    ];
  };

  environment = {
    pathsToLink = ["/share/fish" "/share/qemu"];
    systemPackages = [
      nr
    ];
  };

  networking.hostName = "esi-phone-avf";

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

  system.stateVersion = "25.05";

  systemd = {
    services = {
      # fix for nixpkgs#180175
      NetworkManager-wait-online = {
        serviceConfig.ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
      };
    };
  };

  time.timeZone = "America/New_York";
}
