{pkgs, lib, ...}:

{
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
    };
  };

  users.users.esi.extraGroups = lib.mkDefault ["gamemode"];
}
