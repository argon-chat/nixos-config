{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.nixos-auto-update;
in
{
  options.services.nixos-auto-update = {
    enable = mkEnableOption "automatic NixOS configuration updates from git repository";

    repository = mkOption {
      type = types.str;
      default = "https://github.com/argon-chat/nixos-config.git";
      description = "Git repository URL to pull updates from (use https:// for public repos)";
    };

    branch = mkOption {
      type = types.str;
      default = "master";
      description = "Git branch to track";
    };

    checkInterval = mkOption {
      type = types.str;
      default = "1min";
      description = ''
        How often to check for updates. Uses systemd timer format.
        Examples: "1min", "5min", "hourly", "daily"
      '';
    };

    configPath = mkOption {
      type = types.str;
      default = "/etc/nixos-config";
      description = "Local path where the repository will be cloned";
    };

    autoRebuild = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically rebuild and switch to new configuration when updates are detected";
    };

    notifyOnUpdate = mkOption {
      type = types.bool;
      default = true;
      description = "Log updates to system journal";
    };
  };

  config = mkIf cfg.enable {
    # Ensure git is available
    environment.systemPackages = [ pkgs.git pkgs.openssh ];

    # Script to check for updates and rebuild
    systemd.services.nixos-auto-update = {
      description = "NixOS Auto-Update from Git Repository";
      path = [ pkgs.git pkgs.nixos-rebuild pkgs.coreutils pkgs.openssh pkgs.nettools ];
      
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        set -e

        CONFIG_PATH="${cfg.configPath}"
        REPO="${cfg.repository}"
        BRANCH="${cfg.branch}"

        # Initialize or update the repository
        if [ ! -d "$CONFIG_PATH" ]; then
          echo "Cloning repository for the first time..."
          ${pkgs.git}/bin/git clone --branch "$BRANCH" "$REPO" "$CONFIG_PATH" || {
            echo "Failed to clone repository. Skipping update."
            exit 0
          }
          UPDATED=true
        else
          cd "$CONFIG_PATH"
          
          # Fetch updates
          ${pkgs.git}/bin/git fetch origin "$BRANCH"
          
          # Check if there are updates
          LOCAL=$(${pkgs.git}/bin/git rev-parse HEAD)
          REMOTE=$(${pkgs.git}/bin/git rev-parse origin/"$BRANCH")
          
          if [ "$LOCAL" != "$REMOTE" ]; then
            echo "Updates detected. Pulling changes..."
            ${pkgs.git}/bin/git reset --hard origin/"$BRANCH"
            UPDATED=true
          else
            echo "No updates available."
            UPDATED=false
          fi
        fi

        # Rebuild if updates were found and auto-rebuild is enabled
        if [ "$UPDATED" = true ] && [ "${toString cfg.autoRebuild}" = "1" ]; then
          echo "Rebuilding NixOS configuration..."
          
          # Use the flake from the cloned repository
          if [ -f "$CONFIG_PATH/flake.nix" ]; then
            # Get the hostname
            HOSTNAME=$(${pkgs.nettools}/bin/hostname)
            
            # Try to rebuild with hostname-specific config, fall back to generic
            ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake "$CONFIG_PATH#$HOSTNAME" 2>/dev/null || \
            ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake "$CONFIG_PATH#example" 2>/dev/null || \
            ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake "$CONFIG_PATH" || {
              echo "Failed to rebuild from flake, trying traditional config..."
              # Fallback to traditional configuration
              if [ -f "$CONFIG_PATH/image.nix" ]; then
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch -I nixos-config="$CONFIG_PATH/image.nix"
              else
                echo "No suitable configuration file found. Skipping rebuild."
                exit 0
              fi
            }
          else
            # Fallback to traditional configuration
            if [ -f "$CONFIG_PATH/image.nix" ]; then
              ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch -I nixos-config="$CONFIG_PATH/image.nix"
            else
              echo "No configuration file found. Skipping rebuild."
              exit 0
            fi
          fi
          
          ${if cfg.notifyOnUpdate then ''
            echo "NixOS configuration updated and activated successfully!"
          '' else ""}
        fi
      '';
    };

    # Timer to run the update check periodically
    systemd.timers.nixos-auto-update = {
      description = "Timer for NixOS Auto-Update";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnBootSec = "2min";  # First check 2 minutes after boot
        OnUnitActiveSec = cfg.checkInterval;
        Persistent = true;
      };
    };
  };
}
