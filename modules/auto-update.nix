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
      default = "git@github.com:argon-chat/nixos-config.git";
      description = "Git repository URL to pull updates from";
    };

    deployKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = ''
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
        QyNTUxOQAAACCUfeIoVaurAdSf4jrUNfyWKB9gpNWc+hre3KLjbt5mVwAAAJC020gJtNtI
        CQAAAAtzc2gtZWQyNTUxOQAAACCUfeIoVaurAdSf4jrUNfyWKB9gpNWc+hre3KLjbt5mVw
        AAAEDqUKoflhrj0rBVFlh5yQy4CCe4z8mwjxdARItz2c9RJ5R94ihVq6sB1J/iOtQ1/JYo
        H2Ck1Zz6Gt7couNu3mZXAAAACmRlcGxveS1rZXkBAgM=
        -----END OPENSSH PRIVATE KEY-----
      '';
      description = ''
        SSH private deploy key content for repository access.
        If null, will use default SSH authentication.
        Generate with: ssh-keygen -t ed25519 -C "deploy-key"
        The corresponding public key should be added to GitHub as a deploy key.
      '';
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
      path = [ pkgs.git pkgs.nixos-rebuild pkgs.coreutils pkgs.openssh ];
      
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        set -e

        CONFIG_PATH="${cfg.configPath}"
        REPO="${cfg.repository}"
        BRANCH="${cfg.branch}"
        
        # Setup SSH for git if deploy key is configured
        ${optionalString (cfg.deployKey != null) ''
          # Create temporary deploy key file
          DEPLOY_KEY_FILE=$(mktemp)
          chmod 600 "$DEPLOY_KEY_FILE"
          cat > "$DEPLOY_KEY_FILE" << 'DEPLOYKEY'
          ${cfg.deployKey}
          DEPLOYKEY
          
          export GIT_SSH_COMMAND="ssh -i $DEPLOY_KEY_FILE -o StrictHostKeyChecking=accept-new"
          trap "rm -f $DEPLOY_KEY_FILE" EXIT
        ''}

        # Initialize or update the repository
        if [ ! -d "$CONFIG_PATH" ]; then
          echo "Cloning repository for the first time..."
          ${pkgs.git}/bin/git clone --branch "$BRANCH" "$REPO" "$CONFIG_PATH"
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
            ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake "$CONFIG_PATH#$(hostname)" || \
            ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake "$CONFIG_PATH"
          else
            # Fallback to traditional configuration
            ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch -I nixos-config="$CONFIG_PATH/image.nix"
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
