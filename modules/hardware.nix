{ config, pkgs, lib, ... }:

{
  # Proxmox/QEMU virtualization support
  services.qemuGuest.enable = true;
  
  # Ensure QEMU guest agent package is installed
  environment.systemPackages = [ pkgs.qemu-utils ];
  
  # Enable virtio drivers for better performance
  boot.initrd.availableKernelModules = [ 
    "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio"
  ];
  boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];

  # Networking configuration
  networking.useDHCP = false;
  networking.interfaces = {
    # Proxmox typically uses ens18 for the first network interface
    ens18.useDHCP = true;
  };
  
  # Enable predictable network interface names
  networking.usePredictableInterfaceNames = true;
  
  # Ensure DHCP client is available
  networking.dhcpcd.enable = true;

  # Shared memory configuration (2GB)
  boot.kernel.sysctl = {
    "kernel.shmmax" = 2147483648; # 2GB in bytes
    "kernel.shmall" = 524288; # 2GB in pages (assuming 4KB pages)
  };
}
