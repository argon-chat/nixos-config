#!/usr/bin/env bash

# Quick setup script for NixOS Proxmox Image builder

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}NixOS Proxmox Image - Quick Setup${NC}"
echo ""

# Check if running on NixOS
if [ ! -f /etc/NIXOS ]; then
    echo -e "${YELLOW}Warning: This script is designed for NixOS systems${NC}"
fi

# Check if flakes are enabled
echo -e "${BLUE}Checking if Nix flakes are enabled...${NC}"
if nix flake metadata . &>/dev/null; then
    echo -e "${GREEN}✓ Flakes are enabled${NC}"
else
    echo -e "${YELLOW}Flakes not enabled. Add this to your configuration:${NC}"
    echo ""
    echo "  nix.settings.experimental-features = [ \"nix-command\" \"flakes\" ];"
    echo ""
    echo "Then run: sudo nixos-rebuild switch"
    exit 1
fi

# Update flake lock
echo ""
echo -e "${BLUE}Updating flake inputs...${NC}"
nix flake update

# Show available build targets
echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo "  make build-proxmox  - Build Proxmox VMA image"
echo "  make build-qcow2    - Build QCOW2 image"
echo "  make build-raw      - Build RAW image"
echo "  make check          - Verify configuration"
echo "  make test           - Build and test in VM"
echo ""
echo "Or use nix directly:"
echo "  nix build .#proxmox"
echo "  nix build .#qcow2"
echo "  nix build .#raw"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Customize modules/users.nix with your SSH keys"
echo "2. Update flake.nix with your repository URL"
echo "3. Run: make build-proxmox"
echo "4. Deploy the image to Proxmox"
echo ""
echo "For auto-update setup, see: AUTO-UPDATE-GUIDE.md"
