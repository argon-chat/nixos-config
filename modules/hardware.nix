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

  # Networking default (DHCP is usually fine for a template/base image)
  networking.useDHCP = lib.mkDefault true;
  networking.useNetworkd = lib.mkDefault true;

  # Disk configuration
  virtualisation.diskSize = 100 * 1024; # 100GB in MB
  
  # Memory configuration
  virtualisation.memorySize = 8 * 1024; # 8GB default RAM in MB
  
  # Shared memory configuration (2GB)
  boot.kernel.sysctl = {
    "kernel.shmmax" = 2147483648; # 2GB in bytes
    "kernel.shmall" = 524288; # 2GB in pages (assuming 4KB pages)
  };
}
