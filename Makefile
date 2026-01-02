.PHONY: help build-proxmox build-qcow2 build-raw check update clean test dev

help:
	@echo "NixOS Proxmox Image Builder"
	@echo ""
	@echo "Available targets:"
	@echo "  build-proxmox  - Build Proxmox VMA image"
	@echo "  build-qcow2    - Build QCOW2 image for testing"
	@echo "  build-raw      - Build RAW disk image"
	@echo "  check          - Check flake configuration"
	@echo "  update         - Update flake inputs"
	@echo "  clean          - Remove build artifacts"
	@echo "  test           - Build and run in VM for testing"
	@echo "  dev            - Build development image using nixos-generators"

build-proxmox: clean
	nix build .#proxmox

build-qcow2:
	nix build .#qcow2

build-raw:
	nix build .#raw

check:
	nix flake check

update:
	nix flake update

clean:
	rm -rf result result-*

test:
	nixos-rebuild build-vm --flake .#
	@echo "VM built. Run with: ./result/bin/run-nixos-vm"

dev:
	nix run github:nix-community/nixos-generators -- -f proxmox -c ./image.nix
	@echo "Dev build complete."

dev-copy: build-proxmox
	ssh root@${PROXMOX_HOST} "rm -rf /var/lib/vz/dump/*.vma.zst"
	scp result/*.vma.zst root@${PROXMOX_HOST}:/var/lib/vz/dump/
	@echo "Image copied to Proxmox server."
