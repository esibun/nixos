{pkgs, ...}:

{
  boot.kernelParams = [
    "amd_pstate=active"
    "amd_iommu=on"
    "vfio-pci.ids=1002:13c0" # todo: boot 6900 under vfio driver via specialisation
  ];

  environment.systemPackages = with pkgs; [
    borgbackup
    borgmatic
    cifs-utils
    lact # amd overclocking tools
  ];

  networking = {
    hostName = "esi-nixos";
  };

  programs.kdeconnect.enable = true;

  system.stateVersion = "23.11";

  systemd = {
    packages = with pkgs; [
      lact
    ];
    services = {
      "backup" = {
        wantedBy = [];
        script = ''
          ${pkgs.borgmatic}/bin/borgmatic create -v 1 --list --stats
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
}
