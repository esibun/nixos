{pkgs, lib, config, ...}:

{
  boot.kernelParams = [
    "amd_pstate=active"
    "amd_iommu=on"
    "preempt=full"
  ] ++ lib.optional (config.specialisation != {}) "vfio-pci.ids=1002:13c0";

  specialisation.vfio.configuration = {
    boot.kernelParams = [
      "vfio-pci.ids=1002:73bf,1002:ab28" # 6900 XT (for VFIO gaming)
    ];

    # 6.12.12+ is broken currently (steam instacrashes, LG can't write to LGMP device, see LookingGlass#1159
    boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.linuxKernel.kernels.linux_6_12.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
          sha256 = "sha256-R1Fy/b2HoVPxI6V5Umcudzvbba9bWKQX0aXkGfz+7Ek=";
        };
        version = "6.12.11";
        modDirVersion = "6.12.11";
      };
    }));
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
