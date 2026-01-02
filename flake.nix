{
  description = "NixOS Proxmox Image with Auto-Update Support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }: {
    # Build the Proxmox VMA image
    packages.x86_64-linux = {
      proxmox = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "proxmox";
        modules = [
          ./image.nix
        ];
      };

      # Alternative: Build a raw image
      raw = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "raw";
        modules = [
          ./image.nix
        ];
      };

      # QCOW2 format for testing
      qcow2 = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "qcow";
        modules = [
          ./image.nix
        ];
      };

      default = self.packages.x86_64-linux.proxmox;
    };

    # NixOS module for the auto-update service
    nixosModules.auto-update = import ./modules/auto-update.nix;

    # Example configuration for running systems
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./image.nix
        self.nixosModules.auto-update
      ];
    };
  };
}
