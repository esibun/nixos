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

  # Hasn't been necessary for a while (since MH:Wilds release); though keeping this here just in case drivers decide to break again
  #system = {
  #  replaceDependencies.replacements = (lib.optional (pkgs.unstable.libgbm != pkgs.libgbm) [
  #    {
  #      oldDependency = pkgs.unstable.libgbm;
  #      newDependency = pkgs.libgbm;
  #    }
  #  ]);
  #};

  users = {
    mutableUsers = false;
    users = {
      esi = {
        isNormalUser = true;
        extraGroups = lib.mkDefault ["input" "pipewire" "video" "wheel"];
        hashedPasswordFile = config.age.secrets.esi-passwordfile.path;
      };
    };
  };
}
