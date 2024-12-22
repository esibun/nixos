{pkgs, lib, ...}:

{
  # use kernel that supports SCHED_ISO for gamemode
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        softrealtime = "on";
      };
    };
  };

  users.users.esi.extraGroups = lib.mkDefault ["gamemode"];
}
