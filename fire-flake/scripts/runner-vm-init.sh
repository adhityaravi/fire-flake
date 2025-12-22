#!/usr/bin/env bash
# Bootstrap script for initializing a fresh VM with home-manager
# Run as root: curl -sL <raw-url> | bash
#
# Or: bash runner-vm-init.sh [username] [machine] [git-name] [git-email] [flake-repo-url]

set -euo pipefail

RUNNER_USER="${1:-ivdi}"
MACHINE="${2:-oishiioushi}"
GIT_NAME="${3:-$RUNNER_USER}"
GIT_EMAIL="${4:-$RUNNER_USER@users.noreply.github.com}"
FLAKE_REPO="${5:-https://github.com/adhityaravi/fire-flake.git}"

echo "=== Initializing VM ==="
echo "User:      $RUNNER_USER"
echo "Machine:   $MACHINE"
echo "Git name:  $GIT_NAME"
echo "Git email: $GIT_EMAIL"
echo "Repo:      $FLAKE_REPO"
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
    echo "[4/7] Installing Nix (daemon mode)..."
    sh <(curl -L https://nixos.org/nix/install) --daemon --yes
else
    echo "[4/7] Nix already installed"
fi

# Enable flakes for user
RUNNER_NIX_CONF="/home/$RUNNER_USER/.config/nix"
mkdir -p "$RUNNER_NIX_CONF"
if ! grep -q "experimental-features" "$RUNNER_NIX_CONF/nix.conf" 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> "$RUNNER_NIX_CONF/nix.conf"
fi
chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_NIX_CONF"

# Clone flake repo for runner user
RUNNER_HOME="/home/$RUNNER_USER"
FLAKE_DIR="$RUNNER_HOME/fire-flake"

if [ ! -d "$FLAKE_DIR" ]; then
    echo "[5/7] Cloning flake repo..."
    su - "$RUNNER_USER" -c "git clone $FLAKE_REPO $FLAKE_DIR"
else
    echo "[5/7] Flake repo already exists, pulling latest..."
    su - "$RUNNER_USER" -c "cd $FLAKE_DIR && git fetch origin && git reset --hard origin/main"
fi

# Create vars file for user
echo "[6/7] Creating vars/$RUNNER_USER.nix..."
cat > "$FLAKE_DIR/fire-flake/vars/$RUNNER_USER.nix" << EOF
{
  username = "$RUNNER_USER";
  homeDirectory = "/home/$RUNNER_USER";

  git = {
    name = "$GIT_NAME";
    email = "$GIT_EMAIL";
  };

  stateVersion = "25.11";
}
EOF
chown "$RUNNER_USER:$RUNNER_USER" "$FLAKE_DIR/fire-flake/vars/$RUNNER_USER.nix"

# Disable private config repo (no SSH keys on fresh VM)
echo "Disabling private fire-flake-config input..."
sed -i '/# Optional: if disabled/,/};/d' "$FLAKE_DIR/fire-flake/flake.nix"
rm -f "$FLAKE_DIR/fire-flake/flake.lock"

# Install home-manager and switch to machine config
echo "[7/7] Installing home-manager and applying $MACHINE config..."
su - "$RUNNER_USER" << EOF
    . /etc/profile.d/nix.sh 2>/dev/null || . ~/.nix-profile/etc/profile.d/nix.sh 2>/dev/null || true
    cd $FLAKE_DIR/fire-flake
    nix run home-manager -- switch --impure --flake .#$MACHINE
EOF

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
