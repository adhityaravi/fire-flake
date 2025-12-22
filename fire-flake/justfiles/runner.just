# Justfile for GitHub Actions self-hosted runner management
# Usage: jg runner-setup <REPO_URL> <TOKEN>

# Runner working directory
runner_dir := env_var_or_default("RUNNER_DIR", "~/actions-runner")

# ====================================================================
# RUNNER CONFIGURATION
# ====================================================================

# Configure GH Actions runner (github-runner installed via Nix)
# Usage: jg runner-setup https://github.com/org/repo AXXXX...
runner-setup repo token:
    #!/usr/bin/env bash
    set -euo pipefail

    RUNNER_DIR="{{runner_dir}}"
    RUNNER_DIR="${RUNNER_DIR/#\~/$HOME}"

    echo "Configuring GitHub Actions runner in $RUNNER_DIR..."
    mkdir -p "$RUNNER_DIR"
    cd "$RUNNER_DIR"

    # Configure runner using Nix-installed binary
    config.sh --url "{{repo}}" --token "{{token}}" --unattended --replace --work "$RUNNER_DIR/_work"

    echo ""
    echo "Done! Run 'jg runner-run' to start interactively or 'jg runner-service-install' for systemd"

# Run runner interactively (foreground)
runner-run:
    #!/usr/bin/env bash
    set -euo pipefail
    RUNNER_DIR="{{runner_dir}}"
    RUNNER_DIR="${RUNNER_DIR/#\~/$HOME}"
    cd "$RUNNER_DIR"
    Runner.Listener

# ====================================================================
# SYSTEMD SERVICE
# ====================================================================

# Install runner as systemd user service
runner-service-install:
    #!/usr/bin/env bash
    set -euo pipefail

    RUNNER_DIR="{{runner_dir}}"
    RUNNER_DIR="${RUNNER_DIR/#\~/$HOME}"

    SERVICE_FILE="$HOME/.config/systemd/user/github-runner.service"
    mkdir -p "$(dirname "$SERVICE_FILE")"

    cat > "$SERVICE_FILE" << 'SERVICEEOF'
    [Unit]
    Description=GitHub Actions Runner
    After=network.target

    [Service]
    Type=simple
    WorkingDirectory=RUNNER_DIR_PLACEHOLDER
    ExecStart=RUNNER_LISTENER_PLACEHOLDER
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=default.target
    SERVICEEOF

    # Fix placeholders and remove leading whitespace
    sed -i "s|RUNNER_DIR_PLACEHOLDER|$RUNNER_DIR|g" "$SERVICE_FILE"
    sed -i "s|RUNNER_LISTENER_PLACEHOLDER|$(which Runner.Listener)|g" "$SERVICE_FILE"
    sed -i 's/^    //' "$SERVICE_FILE"

    systemctl --user daemon-reload
    systemctl --user enable github-runner
    systemctl --user start github-runner

    echo "Runner service installed and started"
    systemctl --user status github-runner --no-pager

# Start runner service
runner-service-start:
    systemctl --user start github-runner

# Stop runner service
runner-service-stop:
    systemctl --user stop github-runner

# Check runner service status
runner-service-status:
    systemctl --user status github-runner --no-pager

# Uninstall runner service
runner-service-uninstall:
    systemctl --user stop github-runner || true
    systemctl --user disable github-runner || true
    rm -f ~/.config/systemd/user/github-runner.service
    systemctl --user daemon-reload
    echo "Runner service uninstalled"

# View runner logs
runner-logs:
    journalctl --user -u github-runner -f

# ====================================================================
# CLEANUP
# ====================================================================

# Remove runner configuration
runner-nuke:
    #!/usr/bin/env bash
    set -euo pipefail

    RUNNER_DIR="{{runner_dir}}"
    RUNNER_DIR="${RUNNER_DIR/#\~/$HOME}"

    # Stop service if running
    systemctl --user stop github-runner 2>/dev/null || true
    systemctl --user disable github-runner 2>/dev/null || true
    rm -f ~/.config/systemd/user/github-runner.service
    systemctl --user daemon-reload

    # Remove runner directory
    if [ -d "$RUNNER_DIR" ]; then
        rm -rf "$RUNNER_DIR"
        echo "Runner configuration removed"
    else
        echo "Runner directory not found"
    fi
