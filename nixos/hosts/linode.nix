{pkgs, lib, config, ...}:

{
  imports = [
    ../../hardware-configuration.nix
  ];

  # see https://www.linode.com/docs/guides/install-nixos-on-linode/
  boot = {
    loader = {
      efi.canTouchEfiVariables = lib.mkForce false;
      grub = {
        forceInstall = true;
        device = "nodev";
      };
      systemd-boot.enable = lib.mkForce false;
      timeout = 10;
    };
  };

  environment.systemPackages = with pkgs; [
    # linode stuff
    inetutils
    mtr
    sysstat

    # updater/convenience
    git
    vim
  ];

  networking = {
    hostName = "linode";
    interfaces.eth0.useDHCP = false;
    useDHCP = false;
    usePredictableInterfaceNames = false;
  };

  nix = {
    buildMachines = [{
      hostName = "esi-nixos";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 3;
      speedFactor = 10;
    }];
    gc = {
      automatic = true;
      options = "-d";
    };
    distributedBuilds = true;
    settings.max-jobs = 0;
  };

  users = {
    mutableUsers = false;
    users.esi = {
      isNormalUser = true;
      extraGroups = lib.mkDefault ["input" "pipewire" "video" "wheel"];
      hashedPasswordFile = config.age.secrets.esi-passwordfile.path;
    };
  };

  # see secrets repo for service config

  system.stateVersion = "25.05";
}
