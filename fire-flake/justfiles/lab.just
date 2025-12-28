# Justfile for home lab server management
# Usage: jg <recipe>

# ====================================================================
# ZFS RECIPES
# ====================================================================

# Run any zfs command with sudo
# Usage: jg zfs list
#        jg zfs snapshot tank@backup
#        jg zfs get all tank
zfs *ARGS:
    sudo zfs {{ ARGS }}

# Run any zpool command with sudo
# Usage: jg zpool status
#        jg zpool list
#        jg zpool iostat -v 1
zpool *ARGS:
    sudo zpool {{ ARGS }}

# Show ZFS pool and dataset status overview
zfs-status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Pool Status ==="
    sudo zpool status
    echo ""
    echo "=== Pool List ==="
    sudo zpool list
    echo ""
    echo "=== Dataset List ==="
    sudo zfs list

# Start a scrub on a pool
# Usage: jg zfs-scrub tank
zfs-scrub POOL:
    sudo zpool scrub {{ POOL }}
    echo "Scrub started on {{ POOL }}. Check status with: jg zpool status"

# Show scrub progress
zfs-scrub-status:
    sudo zpool status | grep -A 5 "scan:"

# List all snapshots
zfs-snapshots:
    sudo zfs list -t snapshot

# ====================================================================
# UNATTENDED-UPGRADES RECIPES
# ====================================================================

# Install and configure unattended-upgrades (all updates, reboot notify)
upgrades-setup:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing unattended-upgrades..."
    sudo apt update
    sudo apt install -y unattended-upgrades apt-listchanges

    echo "Configuring auto-upgrades..."
    printf '%s\n' \
        'APT::Periodic::Update-Package-Lists "1";' \
        'APT::Periodic::Unattended-Upgrade "1";' \
        'APT::Periodic::Download-Upgradeable-Packages "1";' \
        'APT::Periodic::AutocleanInterval "7";' \
        | sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null

    echo "Configuring unattended-upgrades..."
    printf '%s\n' \
        'Unattended-Upgrade::Allowed-Origins {' \
        '    "${distro_id}:${distro_codename}";' \
        '    "${distro_id}:${distro_codename}-security";' \
        '    "${distro_id}:${distro_codename}-updates";' \
        '    "${distro_id}ESMApps:${distro_codename}-apps-security";' \
        '    "${distro_id}ESM:${distro_codename}-infra-security";' \
        '};' \
        '' \
        '// Remove unused automatically installed kernel-related packages' \
        'Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";' \
        '' \
        '// Remove unused dependencies' \
        'Unattended-Upgrade::Remove-Unused-Dependencies "true";' \
        '' \
        '// Automatic reboot if required (disabled - notify instead)' \
        'Unattended-Upgrade::Automatic-Reboot "false";' \
        '' \
        '// Syslog logging' \
        'Unattended-Upgrade::SyslogEnable "true";' \
        'Unattended-Upgrade::SyslogFacility "daemon";' \
        | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null

    echo "Enabling unattended-upgrades service..."
    sudo systemctl enable unattended-upgrades
    sudo systemctl start unattended-upgrades

    echo ""
    echo "Done! Unattended-upgrades configured for all updates with reboot notification."
    echo "Check reboot-required: cat /var/run/reboot-required 2>/dev/null || echo 'No reboot needed'"

# Check if a reboot is required
upgrades-reboot-required:
    #!/usr/bin/env bash
    if [ -f /var/run/reboot-required ]; then
        echo "*** System restart required ***"
        cat /var/run/reboot-required.pkgs 2>/dev/null || true
    else
        echo "No reboot required."
    fi

# Show unattended-upgrades status
upgrades-status:
    sudo systemctl status unattended-upgrades

# Run unattended-upgrade manually (dry-run)
upgrades-dry-run:
    sudo unattended-upgrade --dry-run --debug

# Run unattended-upgrade manually
upgrades-run:
    sudo unattended-upgrade -v

# Show recent upgrade logs
upgrades-logs:
    sudo cat /var/log/unattended-upgrades/unattended-upgrades.log 2>/dev/null || echo "No logs yet."

# ====================================================================
# NFS SERVER RECIPES
# ====================================================================

# Install NFS server
nfs-install:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing NFS server..."
    sudo apt update
    sudo apt install -y nfs-kernel-server

    echo "Enabling NFS server..."
    sudo systemctl enable nfs-kernel-server
    sudo systemctl start nfs-kernel-server

    echo ""
    echo "NFS server installed. Add exports to /etc/exports then run: jg nfs-reload"

# Reload NFS exports (after editing /etc/exports)
nfs-reload:
    sudo exportfs -ra
    echo "NFS exports reloaded."

# Show current exports
nfs-exports:
    sudo exportfs -v

# Show NFS server status
nfs-status:
    sudo systemctl status nfs-kernel-server

# Show connected NFS clients
nfs-clients:
    sudo showmount -a 2>/dev/null || echo "No clients connected or showmount not available."

# Add an NFS export (interactive)
# Usage: jg nfs-add-export /path/to/share 192.168.1.0/24
nfs-add-export PATH NETWORK:
    #!/usr/bin/env bash
    set -euo pipefail

    EXPORT_LINE="{{ PATH }} {{ NETWORK }}(rw,sync,no_subtree_check,no_root_squash)"

    echo "Adding export: $EXPORT_LINE"
    echo "$EXPORT_LINE" | sudo tee -a /etc/exports

    echo "Reloading exports..."
    sudo exportfs -ra

    echo "Done! Export added."

# Show /etc/exports
nfs-show-config:
    cat /etc/exports
