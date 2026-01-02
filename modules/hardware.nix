{ config, pkgs, lib, ... }:

{
  # Proxmox/QEMU virtualization support
  services.qemuGuest.enable = true;

  # Networking default (DHCP is usually fine for a template/base image)
  networking.useDHCP = lib.mkDefault true;
}
