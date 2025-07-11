{pkgs, lib, config, ...}:

{
  # see https://www.linode.com/docs/guides/install-nixos-on-linode/
  boot = {
    loader = {
      grub = {
        forceInstall = true;
        device = "nodev";
      };
      timeout = 10;
    };
  };

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
  ];

  networking = {
    hostName = "linode";
    interfaces.eth0.useDHCP = false;
    useDHCP = false;
    usePredictableInterfaceNames = false;
  };

  # see secrets repo for service config

  system.stateVersion = "25.05";
}
