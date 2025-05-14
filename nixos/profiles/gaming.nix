{pkgs, lib, ...}:

{
  # Required for Steam Input to work
  hardware.uinput.enable = true;

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
    };
  };

  users.users.esi.extraGroups = lib.mkDefault ["gamemode" "uinput"];
}
