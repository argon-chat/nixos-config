{ config, pkgs, lib, ... }:

{
  # Helpful base tools baked into the image
  environment.systemPackages = with pkgs; [
    curl
    git
    vim
    python3
    nodejs
  ];
}
