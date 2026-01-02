{ config, pkgs, lib, ... }:

{
  users.mutableUsers = false;

  # Create a normal user and bake in your SSH key
  users.users.aram = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # sudo
    # Set initial password: "nixos" (change after first login: passwd)
    hashedPassword = "$6$rounds=4096$saltysalt$oKbPz1Eoqp6oMxDnQEHZqcN5YlXdcYKYvW8pBP8xQM.nw6VH8r8wF1lZHx/4IVqPYBf3VQGaWnDXVh5Nc7pjF1";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQE9aVJwBA9F3ZgFdJlXEbuMaEVl8ytT1EOJN3RFwj20n7Lz5f8FtwsdP+on11OB+9jLZHD5d5TBxsH8JWEFjvRuvEL0g2jRPXzk2flwevpa1dFe0DcrdZav/AAuu3J98zhH8bFjD6XN+0Fm5qGB99P4mMsm3KZDQYaag/59wsxDEWk5wbgxBs9k1ITpufinM4Rx4u3wFkHIAvNDk/WSQh8P5//ickPR6upIY0NB6cA+/D+qh/UoGSgz33LghUgypvyo6yhqaq0kXJJ0rlsn1CnpmyRNqxEF3htT1TOY1T34bsQHWb6lplT39bjSyqg5w+PNtv+Om/ffVf/LA8lm5l"
    ];
  };

  # Allow sudo without password (optional; remove if you prefer)
  security.sudo.wheelNeedsPassword = false;
}
