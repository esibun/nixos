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

  fileSystems."/mnt/nvme" = {
    device = "/dev/disk/by-uuid/c0bf9375-1a7e-48be-9ec4-23ed80c7b79f";
    fsType = "ext4";
  };

  networking = {
    hostName = "esi-nixos";
    nameservers = [
      "45.90.28.0#esi-nixos-353b61.dns.nextdns.io"
      "45.90.30.0#esi-nixos-353b61.dns.nextdns.io"
    ];
  };

  programs.kdeconnect.enable = true;

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
