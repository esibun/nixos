{pkgs, ...}:

{
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  environment.systemPackages = with pkgs; [
    qemu
    swtpm
    virt-manager
  ];

  systemd.tmpfiles.settings."10-looking-glass" = {
    "/dev/shm/looking-glass" = {
      f = {
        user = "esi";
        group = "kvm";
        mode = "0660";
      };
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
}
