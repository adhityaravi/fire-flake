#!/usr/bin/env bash
# Bootstrap script for initializing a fresh VM as a GitHub Actions runner
# Run as root: curl -sL <raw-url> | bash
#
# Or: bash runner-vm-init.sh [username] [flake-repo-url]

set -euo pipefail

RUNNER_USER="${1:-ivdi}"
FLAKE_REPO="${2:-https://github.com/adhityaravi/fire-flake.git}"

echo "=== Initializing VM for GitHub Actions runner ==="
echo "Runner user: $RUNNER_USER"
echo "Flake repo:  $FLAKE_REPO"
echo ""

# Must be root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Ensure git is installed
if ! command -v git &>/dev/null; then
    echo "[0/6] Installing git..."
    apt-get update && apt-get install -y git
fi

# Create runner user if doesn't exist
if ! id "$RUNNER_USER" &>/dev/null; then
    echo "[1/6] Creating user '$RUNNER_USER'..."
    useradd -m -s /bin/bash "$RUNNER_USER"
else
    echo "[1/6] User '$RUNNER_USER' already exists"
fi

# Add to required groups
echo "[2/6] Configuring groups..."
for group in sudo lxd docker microk8s; do
    getent group "$group" &>/dev/null && usermod -aG "$group" "$RUNNER_USER" || true
done

# Passwordless sudo
echo "[3/6] Configuring passwordless sudo..."
echo "$RUNNER_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$RUNNER_USER
chmod 440 /etc/sudoers.d/$RUNNER_USER

# Install Nix
if [ ! -d "/nix" ]; then
    echo "[4/6] Installing Nix (daemon mode)..."
    sh <(curl -L https://nixos.org/nix/install) --daemon --yes
    # Source nix
    . /etc/profile.d/nix.sh 2>/dev/null || . ~/.nix-profile/etc/profile.d/nix.sh 2>/dev/null || true
else
    echo "[4/6] Nix already installed"
fi

# Clone flake repo for runner user
RUNNER_HOME="/home/$RUNNER_USER"
FLAKE_DIR="$RUNNER_HOME/fire-flake"

if [ ! -d "$FLAKE_DIR" ]; then
    echo "[5/6] Cloning flake repo..."
    su - "$RUNNER_USER" -c "git clone $FLAKE_REPO $FLAKE_DIR"
else
    echo "[5/6] Flake repo already exists, pulling latest..."
    su - "$RUNNER_USER" -c "cd $FLAKE_DIR && git pull"
fi

# Install home-manager and switch to oishiioushi profile
echo "[6/6] Installing home-manager and applying oishiioushi profile..."
su - "$RUNNER_USER" -c "
    . /etc/profile.d/nix.sh 2>/dev/null || . ~/.nix-profile/etc/profile.d/nix.sh 2>/dev/null || true
    cd $FLAKE_DIR/fire-flake
    nix run home-manager -- switch --flake .#oishiioushi
"

echo ""
echo "=== VM initialization complete ==="
echo ""
echo "Next steps:"
echo "  1. Switch to runner user:"
echo "       su - $RUNNER_USER"
echo ""
echo "  2. Get a runner token from GitHub:"
echo "       Settings > Actions > Runners > New self-hosted runner"
echo ""
echo "  3. Configure the runner:"
echo "       jg runner-setup https://github.com/ORG/REPO <TOKEN>"
echo ""
echo "  4. (Optional) Pre-warm charm CI tools:"
echo "       jg runner-prewarm"
echo "       jg runner-prewarm-k8s"
echo ""
echo "  5. Start the runner:"
echo "       jg runner-service-install"
