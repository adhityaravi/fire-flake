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

# Install ZFS utilities
zfs-install:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing ZFS utilities..."
    sudo apt update
    sudo apt install -y zfsutils-linux
    echo "ZFS installed. Verify with: jg zfs-status"

# Run any wipefs command with sudo (for cleaning disks)
# Usage: jg wipefs -a /dev/sda
wipefs *ARGS:
    sudo wipefs {{ ARGS }}

# Run any mdadm command with sudo (for managing RAID arrays)
# Usage: jg mdadm --stop /dev/md127
mdadm *ARGS:
    sudo mdadm {{ ARGS }}

# Show available disks (excludes snap loop devices)
lsblk:
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT | grep -v loop

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

# ====================================================================
# FAN CONTROL RECIPES
# ====================================================================

# Load kernel module for ASRock B760 boards (lm_sensors provides fancontrol tools)
fan-setup:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Loading nct6775 kernel module (Nuvoton Super I/O for ASRock B760)..."
    sudo modprobe nct6775

    echo ""
    echo "Making module load persistent..."
    echo "nct6775" | sudo tee /etc/modules-load.d/nct6775.conf

    echo ""
    echo "Checking for PWM interfaces..."
    ls /sys/class/hwmon/*/pwm* 2>/dev/null || echo "No PWM interfaces found yet. You may need to reboot or check BIOS settings."

    echo ""
    echo "Done! Next steps:"
    echo "  1. Run: jg fan-detect   (detect sensors)"
    echo "  2. Run: jg fan-config   (configure fan curves)"
    echo "  3. Run: jg fan-enable   (enable fancontrol service)"

# Run sensors-detect to find available sensors
fan-detect:
    sudo $HOME/.nix-profile/bin/sensors-detect

# Show all detected sensors and their readings
fan-sensors:
    sensors

# Run pwmconfig to configure fan curves interactively
fan-config:
    sudo $HOME/.nix-profile/bin/pwmconfig

# Show current fancontrol configuration
fan-show-config:
    cat /etc/fancontrol 2>/dev/null || echo "No fancontrol config found. Run: jg fan-config"

# Enable and start fancontrol service
fan-enable:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ ! -f /etc/fancontrol ]; then
        echo "Error: /etc/fancontrol not found. Run 'jg fan-config' first."
        exit 1
    fi

    FANCONTROL_BIN="$HOME/.nix-profile/bin/fancontrol"

    echo "Creating systemd service for fancontrol..."
    printf '%s\n' \
        "[Unit]" \
        "Description=Fan speed regulator (nix)" \
        "ConditionFileNotEmpty=/etc/fancontrol" \
        "After=local-fs.target" \
        "" \
        "[Service]" \
        "Type=simple" \
        "ExecStart=$FANCONTROL_BIN" \
        "Restart=on-failure" \
        "RestartSec=5" \
        "" \
        "[Install]" \
        "WantedBy=multi-user.target" \
        | sudo tee /etc/systemd/system/fancontrol.service > /dev/null

    echo "Reloading systemd..."
    sudo systemctl daemon-reload

    echo "Enabling fancontrol service..."
    sudo systemctl enable fancontrol
    sudo systemctl start fancontrol
    echo "Fancontrol service enabled and started."

# Disable fancontrol service
fan-disable:
    sudo systemctl disable fancontrol
    sudo systemctl stop fancontrol
    echo "Fancontrol service disabled and stopped."

# Show fancontrol service status
fan-status:
    -sudo systemctl status fancontrol --no-pager

# Restart fancontrol service (after config changes)
fan-restart:
    sudo systemctl restart fancontrol
    echo "Fancontrol service restarted."

# Show all hwmon devices and their capabilities
fan-hwmon:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "=== HWMON Devices ==="
    for hwmon in /sys/class/hwmon/hwmon*; do
        name=$(cat "$hwmon/name" 2>/dev/null || echo "unknown")
        echo ""
        echo "--- $hwmon ($name) ---"
        ls "$hwmon" | grep -E "^(fan|pwm|temp)" | head -20 || echo "  (no fan/pwm/temp entries)"
    done

# Show current fan speeds
fan-speeds:
    #!/usr/bin/env bash
    for f in /sys/class/hwmon/*/fan*_input; do
        [ -f "$f" ] && echo "$f: $(cat "$f") RPM"
    done 2>/dev/null || echo "No fan speed sensors found."

# Show current PWM values (0-255)
fan-pwm:
    #!/usr/bin/env bash
    for p in /sys/class/hwmon/*/pwm[0-9]; do
        [ -f "$p" ] && echo "$p: $(cat "$p")/255"
    done 2>/dev/null || echo "No PWM interfaces found."

# Set a specific fan's PWM value (0-255)
# Usage: jg fan-set 1 150
fan-set FAN PWM:
    #!/usr/bin/env bash
    set -euo pipefail
    HWMON=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name" 2>/dev/null)" = "nct6798" ] && echo "$h" && break; done)
    [ -z "$HWMON" ] && echo "Error: nct6798 hwmon not found" && exit 1
    echo "Setting fan{{ FAN }} to manual mode..."
    echo 1 | sudo tee "$HWMON/pwm{{ FAN }}_enable" > /dev/null
    echo "Setting PWM to {{ PWM }}/255..."
    echo {{ PWM }} | sudo tee "$HWMON/pwm{{ FAN }}" > /dev/null
    echo "Done. Fan{{ FAN }} now at PWM {{ PWM }}"

# Set all fans to ultra quiet (~20%)
fan-whisper:
    #!/usr/bin/env bash
    set -euo pipefail
    HWMON=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name" 2>/dev/null)" = "nct6798" ] && echo "$h" && break; done)
    [ -z "$HWMON" ] && echo "Error: nct6798 hwmon not found" && exit 1
    for i in 1 2 3 4 5 6 7; do
        if [ -f "$HWMON/pwm${i}_enable" ]; then
            echo 1 | sudo tee "$HWMON/pwm${i}_enable" > /dev/null
            echo 50 | sudo tee "$HWMON/pwm${i}" > /dev/null
        fi
    done
    echo "All fans set to whisper mode (PWM 50/255)"

# Set all fans to a quiet level (~40%)
fan-quiet:
    #!/usr/bin/env bash
    set -euo pipefail
    HWMON=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name" 2>/dev/null)" = "nct6798" ] && echo "$h" && break; done)
    [ -z "$HWMON" ] && echo "Error: nct6798 hwmon not found" && exit 1
    for i in 1 2 3 4 5 6 7; do
        if [ -f "$HWMON/pwm${i}_enable" ]; then
            echo 1 | sudo tee "$HWMON/pwm${i}_enable" > /dev/null
            echo 100 | sudo tee "$HWMON/pwm${i}" > /dev/null
        fi
    done
    echo "All fans set to quiet mode (PWM 100/255)"

# Set all fans to medium speed (~60%)
fan-medium:
    #!/usr/bin/env bash
    set -euo pipefail
    HWMON=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name" 2>/dev/null)" = "nct6798" ] && echo "$h" && break; done)
    [ -z "$HWMON" ] && echo "Error: nct6798 hwmon not found" && exit 1
    for i in 1 2 3 4 5 6 7; do
        if [ -f "$HWMON/pwm${i}_enable" ]; then
            echo 1 | sudo tee "$HWMON/pwm${i}_enable" > /dev/null
            echo 150 | sudo tee "$HWMON/pwm${i}" > /dev/null
        fi
    done
    echo "All fans set to medium (PWM 150/255)"

# Set all fans to full speed
fan-full:
    #!/usr/bin/env bash
    set -euo pipefail
    HWMON=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name" 2>/dev/null)" = "nct6798" ] && echo "$h" && break; done)
    [ -z "$HWMON" ] && echo "Error: nct6798 hwmon not found" && exit 1
    for i in 1 2 3 4 5 6 7; do
        if [ -f "$HWMON/pwm${i}_enable" ]; then
            echo 1 | sudo tee "$HWMON/pwm${i}_enable" > /dev/null
            echo 255 | sudo tee "$HWMON/pwm${i}" > /dev/null
        fi
    done
    echo "All fans set to full speed (PWM 255/255)"

# Return all fans to BIOS/auto control
fan-auto:
    #!/usr/bin/env bash
    set -euo pipefail
    HWMON=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name" 2>/dev/null)" = "nct6798" ] && echo "$h" && break; done)
    [ -z "$HWMON" ] && echo "Error: nct6798 hwmon not found" && exit 1
    for i in 1 2 3 4 5 6 7; do
        if [ -f "$HWMON/pwm${i}_enable" ]; then
            echo 2 | sudo tee "$HWMON/pwm${i}_enable" > /dev/null 2>&1 || \
            echo 0 | sudo tee "$HWMON/pwm${i}_enable" > /dev/null
        fi
    done
    echo "All fans returned to BIOS/auto control"

# Show full fan status (speeds, PWM values, modes)
fan-info:
    #!/usr/bin/env bash
    HWMON=$(for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name" 2>/dev/null)" = "nct6798" ] && echo "$h" && break; done)
    [ -z "$HWMON" ] && echo "Error: nct6798 hwmon not found" && exit 1
    echo "=== Fan Status (using $HWMON) ==="
    printf "%-6s %-8s %-10s %-12s\n" "Fan" "RPM" "PWM" "Mode"
    printf "%-6s %-8s %-10s %-12s\n" "---" "---" "---" "----"
    for i in 1 2 3 4 5 6 7; do
        rpm=$(cat "$HWMON/fan${i}_input" 2>/dev/null || echo "N/A")
        pwm=$(cat "$HWMON/pwm${i}" 2>/dev/null || echo "N/A")
        enable=$(cat "$HWMON/pwm${i}_enable" 2>/dev/null || echo "?")
        case $enable in
            0) mode="Full" ;;
            1) mode="Manual" ;;
            2) mode="Auto" ;;
            *) mode="Unknown" ;;
        esac
        printf "%-6s %-8s %-10s %-12s\n" "fan$i" "$rpm" "$pwm/255" "$mode"
    done
    echo ""
    echo "=== CPU Temp ==="
    sensors 2>/dev/null | grep -A5 "coretemp" | grep -E "Core|Package" || echo "Run 'sensors' for temps"
