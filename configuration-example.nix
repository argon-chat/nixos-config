# Example configuration for enabling auto-update on a running NixOS system
# 
# Copy the relevant sections to your /etc/nixos/configuration.nix

{ config, pkgs, ... }:

{
  imports = [
    # Your existing imports...
    # /etc/nixos/hardware-configuration.nix
    
    # Import the auto-update module from this repository
    (builtins.fetchGit {
      url = "https://github.com/yourusername/nixos-proxmox-image.git";
      ref = "main";
    } + "/modules/auto-update.nix")
  ];

  # Enable and configure auto-update
  services.nixos-auto-update = {
    enable = true;
    repository = "https://github.com/yourusername/nixos-proxmox-image.git";
    branch = "main";
    
    # Check for updates every minute (configurable)
    checkInterval = "1min";
    
    # Automatically rebuild and switch to new configuration
    autoRebuild = true;
    
    # Where to clone the repository locally
    configPath = "/etc/nixos-config";
    
    # Log updates to system journal
    notifyOnUpdate = true;
  };

  # Your other configuration...
  # networking.hostName = "my-proxmox-vm";
  # time.timeZone = "America/New_York";
  # etc...
}
