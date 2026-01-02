# NixOS Proxmox Image with Auto-Update

A modular NixOS configuration for creating Proxmox-ready VM images with built-in auto-update capabilities from a git repository.

## Features

- 🚀 Modular configuration structure
- 📦 Flake-based builds for reproducibility
- 🔄 Automatic configuration updates from git repository
- 🔒 Hardened SSH configuration
- ⚡ QEMU guest agent support for Proxmox
- 🔧 Configurable update intervals

## Project Structure

```
nixos-proxmox-image/
├── flake.nix                 # Flake configuration for building images
├── image.nix                 # Main configuration entry point
├── modules/
│   ├── hardware.nix          # Hardware and virtualization settings
│   ├── services.nix          # System services (SSH, etc.)
│   ├── users.nix             # User accounts and SSH keys
│   ├── packages.nix          # System packages
│   ├── base.nix              # Base system settings
│   └── auto-update.nix       # Auto-update service module
└── README.md                 # This file
```

## Quick Start

### 1. Building an Image

```bash
# Build Proxmox VMA image
nix build .#proxmox

# Build QCOW2 image (for testing)
nix build .#qcow2

# Build RAW image
nix build .#raw

# The image will be in ./result/
```

### 2. Deploying to Proxmox

```bash
# Upload the VMA image to Proxmox
scp result/*.vma.zst root@proxmox:/var/lib/vz/template/qemu/

# Or use the Proxmox web interface to upload the template
```

### 3. Enabling Auto-Update on Running Systems

Add this to your running system's `/etc/nixos/configuration.nix`:

```nix
{
  imports = [
    # ... your other imports
    (builtins.fetchGit {
      url = "https://github.com/yourusername/nixos-proxmox-image.git";
      ref = "main";
    } + "/modules/auto-update.nix")
  ];

  services.nixos-auto-update = {
    enable = true;
    repository = "https://github.com/yourusername/nixos-proxmox-image.git";
    branch = "main";
    checkInterval = "1min";  # Check every minute
    autoRebuild = true;
  };
}
```

Then rebuild your system:

```bash
sudo nixos-rebuild switch
```

## Configuration

### Auto-Update Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the auto-update service |
| `repository` | string | - | Git repository URL |
| `branch` | string | `"main"` | Git branch to track |
| `checkInterval` | string | `"1min"` | Update check interval (systemd timer format) |
| `configPath` | string | `"/etc/nixos-config"` | Local path for cloned repo |
| `autoRebuild` | bool | `true` | Automatically rebuild on updates |
| `notifyOnUpdate` | bool | `true` | Log updates to journal |

### Customizing Update Intervals

```nix
services.nixos-auto-update.checkInterval = "5min";   # Every 5 minutes
services.nixos-auto-update.checkInterval = "hourly"; # Every hour
services.nixos-auto-update.checkInterval = "daily";  # Once per day
```

### Monitoring Updates

```bash
# Check service status
sudo systemctl status nixos-auto-update.service

# View update logs
sudo journalctl -u nixos-auto-update -f

# Check timer status
sudo systemctl status nixos-auto-update.timer

# List upcoming timer runs
sudo systemctl list-timers nixos-auto-update.timer
```

## Customization

### Adding SSH Keys

Edit [modules/users.nix](modules/users.nix) and add your SSH public key:

```nix
users.users.aram = {
  openssh.authorizedKeys.keys = [
    "ssh-rsa YOUR_PUBLIC_KEY_HERE"
  ];
};
```

### Adding Packages

Edit [modules/packages.nix](modules/packages.nix):

```nix
environment.systemPackages = with pkgs; [
  curl
  git
  vim
  htop        # Add more packages here
  tmux
];
```

### Adding Services

Edit [modules/services.nix](modules/services.nix) or create new module files.

## Security Considerations

- SSH password authentication is disabled by default
- Root login is only permitted with SSH keys
- Sudo is configured without password (change in [modules/users.nix](modules/users.nix) if needed)
- Auto-update pulls from git repository (ensure repository security)

## Development

### Testing Changes Locally

```bash
# Build and test in a VM
nixos-rebuild build-vm --flake .#

# Run the VM
./result/bin/run-nixos-vm
```

### Updating the Flake

```bash
# Update flake inputs
nix flake update

# Check flake
nix flake check
```

## Troubleshooting

### Auto-update not working

1. Check if the service is enabled:
   ```bash
   sudo systemctl status nixos-auto-update.timer
   ```

2. Manually trigger an update:
   ```bash
   sudo systemctl start nixos-auto-update.service
   ```

3. Check logs for errors:
   ```bash
   sudo journalctl -u nixos-auto-update -n 50
   ```

### Build failures

```bash
# Clean build directory
rm -rf result

# Rebuild with verbose output
nix build .#proxmox --verbose
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build
5. Submit a pull request

## License

MIT License - feel free to use and modify as needed.

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-generators](https://github.com/nix-community/nixos-generators)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)

# Auto-Update Quick Reference

## Overview

The auto-update service automatically pulls configuration changes from this git repository and rebuilds your NixOS system. It runs as a systemd timer that checks for updates at configurable intervals.

## How It Works

1. **Timer Trigger**: The systemd timer triggers at the specified interval
2. **Git Check**: The service checks if there are new commits in the remote repository
3. **Pull Changes**: If updates exist, it pulls the latest changes
4. **Rebuild**: If `autoRebuild` is enabled, it automatically runs `nixos-rebuild switch`
5. **Logging**: All actions are logged to the system journal

## Configuration Options

### Basic Setup

```nix
services.nixos-auto-update = {
  enable = true;
  repository = "https://github.com/yourusername/nixos-proxmox-image.git";
  branch = "main";
  checkInterval = "1min";
};
```

### All Available Options

```nix
services.nixos-auto-update = {
  # Enable/disable the service
  enable = true;

  # Git repository URL (HTTPS or SSH)
  repository = "https://github.com/yourusername/nixos-proxmox-image.git";
  # For SSH: "git@github.com:yourusername/nixos-proxmox-image.git"

  # Branch to track
  branch = "main";

  # Update check interval (systemd timer syntax)
  checkInterval = "1min";  # Options: "1min", "5min", "hourly", "daily", etc.

  # Local path for cloned repository
  configPath = "/etc/nixos-config";

  # Automatically rebuild when updates are found
  autoRebuild = true;

  # Log updates to journal
  notifyOnUpdate = true;
};
```

## Systemd Commands

### Service Management

```bash
# Start an immediate check
sudo systemctl start nixos-auto-update.service

# Check service status
sudo systemctl status nixos-auto-update.service

# View service logs
sudo journalctl -u nixos-auto-update.service

# Follow logs in real-time
sudo journalctl -u nixos-auto-update.service -f

# View last 50 log entries
sudo journalctl -u nixos-auto-update.service -n 50
```

### Timer Management

```bash
# Check timer status
sudo systemctl status nixos-auto-update.timer

# List all timers including this one
sudo systemctl list-timers

# View when next update will run
sudo systemctl list-timers nixos-auto-update.timer

# Stop the timer (disable auto-updates temporarily)
sudo systemctl stop nixos-auto-update.timer

# Start the timer again
sudo systemctl start nixos-auto-update.timer

# Disable timer permanently (survives reboot)
sudo systemctl disable nixos-auto-update.timer

# Enable timer permanently
sudo systemctl enable nixos-auto-update.timer
```

## Common Scenarios

### Scenario 1: Check every 5 minutes instead of 1 minute

```nix
services.nixos-auto-update.checkInterval = "5min";
```

Then rebuild: `sudo nixos-rebuild switch`

### Scenario 2: Only check, don't auto-rebuild

```nix
services.nixos-auto-update = {
  enable = true;
  autoRebuild = false;  # Set to false
  # ... other options
};
```

Then manually rebuild when you see updates in logs:
```bash
sudo journalctl -u nixos-auto-update -f
# When you see "Updates detected", manually run:
sudo nixos-rebuild switch --flake /etc/nixos-config
```

### Scenario 3: Use SSH instead of HTTPS

```nix
services.nixos-auto-update.repository = "git@github.com:yourusername/nixos-proxmox-image.git";
```

Make sure SSH keys are set up for root:
```bash
sudo ssh-keygen -t ed25519
sudo cat /root/.ssh/id_ed25519.pub  # Add to GitHub
```

### Scenario 4: Track a different branch

```nix
services.nixos-auto-update.branch = "stable";  # or "development", etc.
```

### Scenario 5: Disable auto-update temporarily

```bash
# Stop the timer (won't start on reboot)
sudo systemctl stop nixos-auto-update.timer
sudo systemctl disable nixos-auto-update.timer

# Re-enable later
sudo systemctl enable nixos-auto-update.timer
sudo systemctl start nixos-auto-update.timer
```

## Security Considerations

1. **Repository Access**: Ensure your git repository is secure. Anyone with write access can push configuration changes that will be auto-applied.

2. **SSH Keys**: If using SSH, protect the root SSH private key with appropriate permissions.

3. **Testing**: Consider using a `testing` or `staging` branch first before auto-updating production systems.

4. **Rollbacks**: NixOS keeps previous generations. If an update breaks something:
   ```bash
   # List available generations
   sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
   
   # Rollback to previous generation
   sudo nixos-rebuild switch --rollback
   
   # Or boot into a previous generation from GRUB
   ```

## Troubleshooting

### Updates not happening

1. Check timer is running:
   ```bash
   sudo systemctl is-active nixos-auto-update.timer
   ```

2. Check for errors:
   ```bash
   sudo journalctl -u nixos-auto-update -n 50 --no-pager
   ```

3. Manually trigger:
   ```bash
   sudo systemctl start nixos-auto-update.service
   ```

### Git authentication failures

For HTTPS with private repos, set up credential helper:
```bash
sudo git config --global credential.helper store
```

For SSH, ensure keys are set up:
```bash
sudo ssh -T git@github.com
```

### Build failures

Check the journal for the full error:
```bash
sudo journalctl -u nixos-auto-update -n 100 --no-pager
```

Disable auto-rebuild and test manually:
```nix
services.nixos-auto-update.autoRebuild = false;
```

Then rebuild manually:
```bash
cd /etc/nixos-config
sudo nixos-rebuild switch --flake .
```

## Monitoring

### Create a simple monitoring script

```bash
#!/usr/bin/env bash
# /usr/local/bin/check-auto-update.sh

echo "=== Auto-Update Status ==="
echo ""
echo "Timer Status:"
systemctl status nixos-auto-update.timer | grep "Active:"
echo ""
echo "Last Run:"
journalctl -u nixos-auto-update -n 1 --no-pager
echo ""
echo "Next Run:"
systemctl list-timers nixos-auto-update.timer --no-pager | tail -n 1
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/check-auto-update.sh
```

## Best Practices

1. **Test First**: Test configuration changes in a non-production VM first
2. **Use Branches**: Use separate branches for production and testing
3. **Monitor Logs**: Regularly check logs for successful updates
4. **Set Reasonable Intervals**: 1 minute might be too frequent for production
5. **Keep Backups**: Despite NixOS's rollback capability, maintain backups
6. **Document Changes**: Use clear git commit messages for tracking changes
