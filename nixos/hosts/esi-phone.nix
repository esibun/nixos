{lib, pkgs, inputs, config, ...}:

{
  networking = {
    hostName = "esi-phone-avf";
    networkmanager.enable = lib.mkForce false;
  };

  system.stateVersion = "25.05";
}
