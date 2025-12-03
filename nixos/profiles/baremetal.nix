{lib, pkgs, inputs, config, ...}:

{
  imports = [
    ../../hardware-configuration.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
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

  users = {
    mutableUsers = false;
    groups.nixbuilder = {};
    users = {
      esi = {
        isNormalUser = true;
        extraGroups = lib.mkDefault ["input" "pipewire" "video" "wheel"];
        hashedPasswordFile = config.age.secrets.esi-passwordfile.path;
      };
      nixbuilder = {
        isNormalUser = true;
        group = "nixbuilder";
        hashedPassword = "!"; # disable the account
      };
    };
  };
}
