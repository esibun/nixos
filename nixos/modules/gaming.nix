{pkgs, lib, ...}:

{
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
