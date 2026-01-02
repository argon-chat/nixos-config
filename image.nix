{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/hardware.nix
    ./modules/services.nix
    ./modules/users.nix
    ./modules/packages.nix
    ./modules/base.nix
    ./modules/auto-update.nix
  ];
  
  # Auto-update disabled by default
  # Enable in your running system configuration if needed: services.nixos-auto-update.enable = true
  services.nixos-auto-update.enable = lib.mkDefault false;
}
