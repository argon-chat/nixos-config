{ config, pkgs, lib, ... }:

let
  # Read auto-update setting from environment variable
  # Usage: NIXOS_AUTO_UPDATE=false nix build (to disable during build)
  autoUpdateEnv = builtins.getEnv "NIXOS_AUTO_UPDATE";
  autoUpdateEnabled = if autoUpdateEnv == "" then true
                      else (autoUpdateEnv != "false" && autoUpdateEnv != "0");
in
{
  imports = [
    ./modules/hardware.nix
    ./modules/services.nix
    ./modules/users.nix
    ./modules/packages.nix
    ./modules/base.nix
    ./modules/auto-update.nix
  ];
  
  # Auto-update enabled by default
  # Disable during build with: NIXOS_AUTO_UPDATE=false nix build
  # Or override in configuration: services.nixos-auto-update.enable = false
  services.nixos-auto-update.enable = lib.mkDefault autoUpdateEnabled;
}
