{pkgs, ...}:

{
  networking = {
    hostName = "esi-laptop";
    nameservers = [
      "45.90.28.0#esi-laptop-353b61.dns.nextdns.io"
      "45.90.30.0#esi-laptop-353b61.dns.nextdns.io"
    ];
  };

  services = {
    fwupd.enable = true; # framework firmware updates through fwupd
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM="backlight", RUN+="${pkgs.coreutils-full}/bin/chgrp video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM="backlight", RUN+="${pkgs.coreutils-full}/bin/chmod g+w video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM="leds", RUN+="${pkgs.coreutils-full}/bin/chgrp video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM="leds", RUN+="${pkgs.coreutils-full}/bin/chmod g+w /sys/class/backlight/%k/brightness"
      ACTION=="change", SUBSYSTEM="backlight", OPTIONS:="nowatch"
    ''; # allow video group to adjust backlight settings
  };

  virtualisation.containers.enable = true; # podman
}
