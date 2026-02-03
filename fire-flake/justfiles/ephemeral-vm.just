# Ephemeral VMs - get in, do stuff, get out, forget about it, like a toxic fuckboy. or fuck person i suppose.
# Hacky but lightweight qemu direct based virtualizer using just recipes.
# Usage: jg vm-shell ubuntu 24.04

vm_dir := env_var('HOME') + "/.local/share/ephemeral-vms"
ssh_key := env_var('HOME') + "/.ssh/id_ed25519.pub"  # make this configurable
mem := "2048"
cpus := "2"
disk := "20G"

# Get into an ephemeral VM
# Usage: jg vm-shell ubuntu 24.04
#        jg mem=4096 cpus=4 disk=50G vm-shell ubuntu 24.04
vm-shell distro version: (_ensure-image distro version) (_ensure-cloudinit)
    #!/usr/bin/env bash
    set -euo pipefail

    BASE_IMG="{{vm_dir}}/{{distro}}-{{version}}.qcow2"
    OVERLAY="{{vm_dir}}/overlay-$$.qcow2"

    if [ ! -f "$BASE_IMG" ]; then
        echo "Image not found: $BASE_IMG"
        exit 1
    fi

    # Create temporary overlay with desired disk size
    qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMG" "$OVERLAY" {{disk}} >/dev/null

    # Cleanup overlay on exit
    trap "rm -f '$OVERLAY'" EXIT

    echo "Launching {{distro}} {{version}} | {{mem}}MB RAM | {{cpus}} CPUs | {{disk}} disk"
    echo "SSH: ssh -p 2222 ivdi@localhost (from another terminal)"
    echo "Exit: Ctrl-a x"
    echo ""

    qemu-system-x86_64 \
        -enable-kvm -cpu host -m {{mem}} -smp {{cpus}} \
        -drive file="$OVERLAY",if=virtio,format=qcow2 \
        -drive file="{{vm_dir}}/cidata.iso",if=virtio,media=cdrom \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0 \
        -nographic

vm-ssh:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 ivdi@localhost

vm-list:
    #!/usr/bin/env bash
    echo "Cached images:"
    ls -1 "{{vm_dir}}"/*.qcow2 2>/dev/null | xargs -I{} basename {} .qcow2 || echo "  (none)"
    echo ""
    echo "Available: jg vm-versions"

vm-versions:
    @echo "Ubuntu:  25.10 25.04 24.10 24.04 23.10 22.04 20.04"
    @echo "Fedora:  41 40 39 38"
    @echo "Debian:  13 12 11 10"

vm-remove distro version:
    rm -f "{{vm_dir}}/{{distro}}-{{version}}.qcow2"
    @echo "Removed {{distro}}-{{version}}"

vm-purge-all:
    rm -rf "{{vm_dir}}"
    @echo "Purged all VMs and images"

[private]
_ensure-image distro version:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{vm_dir}}"
    IMG="{{vm_dir}}/{{distro}}-{{version}}.qcow2"

    [ -f "$IMG" ] && exit 0

    # This is ugly. quickget is elegant but doesnt seem to fetch cloud images just isos. So ugly it is.
    case "{{distro}}-{{version}}" in
        # Ubuntu cloud images
        ubuntu-25.10) URL="https://cloud-images.ubuntu.com/questing/current/questing-server-cloudimg-amd64.img" ;;
        ubuntu-25.04) URL="https://cloud-images.ubuntu.com/plucky/current/plucky-server-cloudimg-amd64.img" ;;
        ubuntu-24.10) URL="https://cloud-images.ubuntu.com/oracular/current/oracular-server-cloudimg-amd64.img" ;;
        ubuntu-24.04) URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img" ;;
        ubuntu-23.10) URL="https://cloud-images.ubuntu.com/mantic/current/mantic-server-cloudimg-amd64.img" ;;
        ubuntu-22.04) URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" ;;
        ubuntu-20.04) URL="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img" ;;

        # Fedora cloud images
        fedora-41) URL="https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2" ;;
        fedora-40) URL="https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2" ;;
        fedora-39) URL="https://download.fedoraproject.org/pub/fedora/linux/releases/39/Cloud/x86_64/images/Fedora-Cloud-Base-39-1.5.x86_64.qcow2" ;;
        fedora-38) URL="https://download.fedoraproject.org/pub/fedora/linux/releases/38/Cloud/x86_64/images/Fedora-Cloud-Base-38-1.6.x86_64.qcow2" ;;

        # Debian cloud images
        debian-13) URL="https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2" ;;
        debian-12) URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2" ;;
        debian-11) URL="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2" ;;
        debian-10) URL="https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2" ;;

        *)
            echo "Unknown: {{distro}}-{{version}}"
            echo "Run: jg vm-versions"
            exit 1
            ;;
    esac

    echo "Downloading {{distro}} {{version}}..."
    curl -L --progress-bar -o "$IMG" "$URL"
    echo "Done: $IMG"

[private]
_ensure-cloudinit:
    #!/usr/bin/env bash
    [ -f "{{vm_dir}}/cidata.iso" ] && exit 0
    mkdir -p "{{vm_dir}}"
    SSH_PUBKEY=$(cat "{{ssh_key}}" 2>/dev/null || echo "")
    printf '%s\n' "#cloud-config" \
        "users:" \
        "  - name: ivdi" \
        "    sudo: ALL=(ALL) NOPASSWD:ALL" \
        "    shell: /bin/bash" \
        "    ssh_authorized_keys:" \
        "      - $SSH_PUBKEY" \
        "ssh_pwauth: false" \
        "hostname: camphor" \
        "package_update: true" \
        "packages:" \
        "  - fastfetch" \
        "growpart:" \
        "  mode: auto" \
        "  devices: [/]" \
        "resize_rootfs: true" \
        "write_files:" \
        "  - path: /etc/profile.d/term.sh" \
        "    content: |" \
        "      export TERM=xterm-256color" > "{{vm_dir}}/user-data"
    echo "instance-id: ephemeral" > "{{vm_dir}}/meta-data"
    printf '%s\n' "version: 2" \
        "ethernets:" \
        "  id0:" \
        "    match:" \
        "      driver: virtio*" \
        "    dhcp4: true" > "{{vm_dir}}/network-config"
    cd "{{vm_dir}}"
    genisoimage -output cidata.iso -V cidata -r -J user-data meta-data network-config 2>/dev/null || \
    mkisofs -output cidata.iso -V cidata -r -J user-data meta-data network-config 2>/dev/null || \
    xorriso -as genisoimage -output cidata.iso -V cidata -r -J user-data meta-data network-config
