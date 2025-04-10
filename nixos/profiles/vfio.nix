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

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf = {
        enable = true;
        packages = [
          pkgs.OVMFFull.fd
        ];
      };
      swtpm.enable = true;
    };
  };
}
