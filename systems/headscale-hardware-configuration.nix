{
  modulesPath,
  lib,
  ...
}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];
  boot = {
    loader.grub.device = "/dev/vda";
    initrd = {
      availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
      kernelModules = ["nvme"];
    };
  };
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
  swapDevices = [{device = "/dev/vda2";}];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
