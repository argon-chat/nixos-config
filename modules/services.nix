{ config, pkgs, lib, ... }:

{
  # SSH service
  services.openssh.enable = true;

  # SSH configuration
  services.openssh.settings = {
    # Enable password authentication (set to false after adding your SSH keys)
    PasswordAuthentication = true;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };
  
  # Firewall configuration
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
}
