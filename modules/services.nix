{ config, pkgs, lib, ... }:

{
  # SSH service
  services.openssh.enable = true;

  # SSH hardening + key-based login
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };
}
