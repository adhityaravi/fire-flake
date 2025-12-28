# Justfile for managing Tailscale service (home-manager managed binary)
# Usage: jg tailscale-setup

# ====================================================================
# TAILSCALE RECIPES
# ====================================================================

# Install and enable the tailscaled systemd service
tailscale-setup:
    #!/usr/bin/env bash
    set -euo pipefail

    SERVICE_FILE="$HOME/.config/tailscale/tailscaled.service"

    if [ ! -f "$SERVICE_FILE" ]; then
        echo "Error: Service file not found at $SERVICE_FILE"
        echo "Make sure you've run 'home-manager switch' with tailscale enabled."
        exit 1
    fi

    echo "Installing tailscaled systemd service..."
    sudo cp "$SERVICE_FILE" /etc/systemd/system/tailscaled.service

    echo "Reloading systemd daemon..."
    sudo systemctl daemon-reload

    # Unmask in case it was masked by previous apt removal
    echo "Unmasking tailscaled service (if masked)..."
    sudo systemctl unmask tailscaled 2>/dev/null || true

    echo "Enabling and starting tailscaled service..."
    sudo systemctl enable tailscaled
    sudo systemctl restart tailscaled

    echo ""
    echo "Done! Run 'jg ts up'"

# Stop and disable the tailscaled service
tailscale-stop:
    sudo systemctl stop tailscaled
    sudo systemctl disable tailscaled

# Run any tailscale command with sudo (handles PATH)
# Usage: jg ts up --ssh
#        jg ts status
#        jg ts down
ts *ARGS:
    sudo env "PATH=$PATH" tailscale {{ ARGS }}

# Remove the tailscaled systemd service completely
tailscale-nuke:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Stopping tailscaled service..."
    sudo systemctl stop tailscaled || true
    sudo systemctl disable tailscaled || true

    echo "Removing systemd service file..."
    sudo rm -f /etc/systemd/system/tailscaled.service

    echo "Reloading systemd daemon..."
    sudo systemctl daemon-reload

    echo "Done! Tailscale service removed."
    echo "Note: The tailscale package is still installed via home-manager."
