{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/hardware.nix
    ./modules/services.nix
    ./modules/users.nix
    ./modules/packages.nix
    ./modules/base.nix
  ];
}
