{pkgs, lib, config, ...}:

{
  specialisation.vfio.configuration = {
    boot.kernelParams = [
      "vfio-pci.ids=1002:73bf,1002:ab28" # 6900 XT (for VFIO gaming)
    ];
  };

  environment.systemPackages = with pkgs; [
    borgbackup
    borgmatic
    cifs-utils
    lact # amd overclocking tools
  ];

  hardware.amdgpu.amdvlk.enable = true;

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
}
