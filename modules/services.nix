{ config, pkgs, lib, ... }:

{
  # SSH service
  services.openssh.enable = true;

  # SSH configuration
  services.openssh.settings = {
    # Enable password authentication (set to false after adding your SSH keys)
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };
  
  # Open SSH port in firewall
  networking.firewall.allowedTCPPorts = [ 22 ];
}
