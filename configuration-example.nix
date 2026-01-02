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
      url = "https://github.com/argon-chat/nixos-config.git";
      ref = "main";
    } + "/modules/auto-update.nix")
  ];

  # Enable and configure auto-update
  services.nixos-auto-update = {
    enable = true;
    repository = "git@github.com:argon-chat/nixos-config.git";
    branch = "main";
    
    # IMPORTANT: Paste your SSH private deploy key here
    # Generate with: ssh-keygen -t ed25519 -C "nixos-deploy"
    # Then add the PUBLIC key to GitHub as a deploy key with read access
    deployKey = ''
      -----BEGIN OPENSSH PRIVATE KEY-----
      PASTE_YOUR_PRIVATE_KEY_HERE
      -----END OPENSSH PRIVATE KEY-----
    '';
    
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
