# Justfile for GitHub Actions self-hosted runner management
# Usage: jg runner-setup <REPO_URL> <TOKEN>

# Runner working directory
runner_dir := env_var_or_default("RUNNER_DIR", "~/actions-runner")

# ====================================================================
# RUNNER CONFIGURATION
# ====================================================================

# Configure GH Actions runner (github-runner installed via Nix)
# Usage: jg runner-setup REPO TOKEN LABELS
# Example: jg runner-setup https://github.com/org/repo AXXXX... self-hosted,Linux,X64,charm-ci
runner-setup repo token labels:
    #!/usr/bin/env bash
    set -euo pipefail

    RUNNER_DIR="{{runner_dir}}"
    RUNNER_DIR="${RUNNER_DIR/#\~/$HOME}"

    echo "Configuring GitHub Actions runner in $RUNNER_DIR..."
    mkdir -p "$RUNNER_DIR"

    # RUNNER_ROOT is required for nixpkgs github-runner (nix store is read-only)
    export RUNNER_ROOT="$RUNNER_DIR"
    cd "$RUNNER_DIR"

    # Configure runner (--no-default-labels removes self-hosted,Linux,X64)
    config.sh --url "{{repo}}" --token "{{token}}" --labels "{{labels}}" --no-default-labels --unattended --replace --disableupdate --work "$RUNNER_DIR/_work"

    echo ""
    echo "Done! Run 'jg runner-run' to start interactively or 'jg runner-service-install' for systemd"

# Run runner interactively (foreground)
runner-run:
    #!/usr/bin/env bash
    set -euo pipefail
    RUNNER_DIR="{{runner_dir}}"
    RUNNER_DIR="${RUNNER_DIR/#\~/$HOME}"
    export RUNNER_ROOT="$RUNNER_DIR"
    cd "$RUNNER_DIR"
    run.sh

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

    cat > "$SERVICE_FILE" << SERVICEEOF
    [Unit]
    Description=GitHub Actions Runner
    After=network.target

    [Service]
    Type=simple
    WorkingDirectory=$RUNNER_DIR
    Environment=RUNNER_ROOT=$RUNNER_DIR
    ExecStart=$(which run.sh)
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=default.target
    SERVICEEOF

    # Remove leading whitespace from heredoc
    sed -i 's/^    //' "$SERVICE_FILE"

    systemctl --user daemon-reload
    systemctl --user enable github-runner
    systemctl --user start github-runner

    echo "Runner service installed and started"
    systemctl --user status github-runner --no-pager || true

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

# Remove runner configuration completely
# Usage: jg runner-nuke <TOKEN>  (token needed to deregister from GitHub)
runner-nuke token="":
    #!/usr/bin/env bash
    set -euo pipefail

    RUNNER_DIR="{{runner_dir}}"
    RUNNER_DIR="${RUNNER_DIR/#\~/$HOME}"

    # Stop service if running
    echo "Stopping runner service..."
    systemctl --user stop github-runner 2>/dev/null || true
    systemctl --user disable github-runner 2>/dev/null || true
    rm -f ~/.config/systemd/user/github-runner.service
    systemctl --user daemon-reload

    # Deregister from GitHub if token provided and config exists
    if [ -n "{{token}}" ] && [ -f "$RUNNER_DIR/.runner" ]; then
        echo "Deregistering runner from GitHub..."
        export RUNNER_ROOT="$RUNNER_DIR"
        cd "$RUNNER_DIR"
        config.sh remove --token "{{token}}" || true
    fi

    # Remove runner directory
    if [ -d "$RUNNER_DIR" ]; then
        rm -rf "$RUNNER_DIR"
        echo "Runner directory removed"
    else
        echo "Runner directory not found"
    fi

    echo "Runner nuked successfully"
