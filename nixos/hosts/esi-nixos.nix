{pkgs, lib, config, ...}:

{
  environment.systemPackages = with pkgs; [
    borgbackup
    borgmatic
    cifs-utils
    distrobox
    lact # amd overclocking tools
  ];

  networking = {
    hostName = "esi-nixos";
  };

  services = {
    avahi.enable = true;
    printing.enable = true;
    usbmuxd.enable = true;
  };

  system.stateVersion = "23.11";

  systemd = {
    packages = with pkgs; [
      lact
    ];
    services = {
      "backup" = {
        wantedBy = [];
        script = ''
          ${pkgs.borgmatic}/bin/borgmatic -v 1 --list --stats
          '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Environment = "PATH=/run/wrappers/bin:$PATH";
        };
      };
      lactd = {
        enable = true;
        wantedBy = ["multi-user.target"];
      };
    };
    timers."backup" = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1h";
        OnUnitActiveSec = "1h";
        Unit = "backup.service";
      };
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
