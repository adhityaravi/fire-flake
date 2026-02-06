# Justfile for setting up and nuking a charm development environment
# Usage: jg k8s=ck8s charmdev-setup  (or k8s=microk8s, which is the default)

# Default Kubernetes flavor: "microk8s" or "ck8s"
k8s := "microk8s"

# ====================================================================
# MICROK8S RECIPES
# ====================================================================

[private]
charmdev-microk8s-install:
    # Install Juju and MicroK8s (kubectl provided by nix)
    sudo snap install juju --channel=3.6/stable
    sudo snap install microk8s --channel=1.32/stable --classic

[private]
charmdev-microk8s-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    # Configure MicroK8s and enable required addons
    sudo usermod -a -G microk8s $USER
    sudo microk8s status --wait-ready
    sudo microk8s enable metrics-server
    sudo microk8s kubectl rollout status deployments/metrics-server -n kube-system -w --timeout=600s
    sudo microk8s enable dns
    sudo microk8s kubectl rollout status deployments/coredns -n kube-system -w --timeout=600s
    sudo microk8s enable rbac
    sudo microk8s enable hostpath-storage
    sudo microk8s kubectl rollout status deployments/hostpath-provisioner -n kube-system -w --timeout=600s
    IPADDR=$(ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc')
    IFS='.' read -r a b c d <<< "$IPADDR"
    sudo microk8s enable metallb:$IPADDR-$a.$b.$c.$((d + 9))
    sudo microk8s kubectl rollout status daemonset.apps/speaker -n metallb-system -w --timeout=600s
    sudo microk8s enable registry
    sudo microk8s kubectl rollout status deployment.apps/registry -n container-registry -w --timeout=600s

[private]
charmdev-microk8s-juju-bootstrap:
    # Bootstrap MicroK8s controller and create default model
    sudo microk8s config | juju add-k8s mcrk8s --client
    juju bootstrap mcrk8s mcrk8s
    juju add-model --config logging-config="<root>=WARNING; unit=DEBUG" \
                   --config update-status-hook-interval="60m" welcome-k8s

[private]
charmdev-microk8s-export-kubeconfig:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p $HOME/.kube
    MACHINE=$(hostname | grep -oE '(kuma|inu|neko)$')
    # Export and rename to machine-specific names
    sudo microk8s config | \
        yq ".clusters[0].name = \"${MACHINE}-cluster\" |
            .contexts[0].name = \"${MACHINE}\" |
            .contexts[0].context.cluster = \"${MACHINE}-cluster\" |
            .contexts[0].context.user = \"${MACHINE}-admin\" |
            .users[0].name = \"${MACHINE}-admin\" |
            .\"current-context\" = \"${MACHINE}\"" > /tmp/config-${MACHINE}-tmp
    # Merge or create
    if [ -f "$HOME/.kube/config" ]; then
        # Remove old entries for this machine, then merge
        yq "del(.clusters[] | select(.name == \"${MACHINE}-cluster\")) |
            del(.contexts[] | select(.name == \"${MACHINE}\")) |
            del(.users[] | select(.name == \"${MACHINE}-admin\"))" $HOME/.kube/config > /tmp/config-existing-tmp
        yq eval-all 'select(fileIndex == 0) *+ select(fileIndex == 1) | .current-context = "'"${MACHINE}"'"' /tmp/config-existing-tmp /tmp/config-${MACHINE}-tmp > $HOME/.kube/config
        rm -f /tmp/config-existing-tmp
    else
        mv /tmp/config-${MACHINE}-tmp $HOME/.kube/config
    fi
    rm -f /tmp/config-${MACHINE}-tmp
    echo "Kubeconfig merged for ${MACHINE}"

[private]
charmdev-microk8s-nuke:
    #!/usr/bin/env bash
    set -euo pipefail
    # Destroy Juju controllers and remove Juju/MicroK8s
    sudo snap remove --purge juju || true
    sudo snap remove --purge microk8s || true
    rm -rf ~/.local/share/juju ~/.cache/juju ~/.config/juju
    sudo rm -rf /var/snap/juju /var/snap/microk8s
    sudo rm -rf /run/containerd
    # Remove only this machine's kubeconfig entries (preserve others)
    MACHINE=$(hostname | grep -oE '(kuma|inu|neko)$')
    if [ -f "$HOME/.kube/config" ]; then
        yq "del(.clusters[] | select(.name == \"${MACHINE}-cluster\")) |
            del(.contexts[] | select(.name == \"${MACHINE}\")) |
            del(.users[] | select(.name == \"${MACHINE}-admin\"))" $HOME/.kube/config > /tmp/config-cleaned
        mv /tmp/config-cleaned $HOME/.kube/config
        echo "Removed ${MACHINE} entries from kubeconfig"
    fi

# ====================================================================
# CANONICAL K8S RECIPES
# ====================================================================

[private]
charmdev-ck8s-install:
    # Install Juju and Canonical K8s
    sudo snap install juju --channel=3.6/stable
    sudo snap install k8s --classic --channel=1.32-classic/stable
    sudo snap install kubectl --classic

[private]
charmdev-ck8s-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    # Bootstrap Canonical K8s and enable required features
    sudo k8s bootstrap
    sudo k8s status --wait-ready
    # Enable DNS (CoreDNS)
    sudo k8s enable dns
    sudo k8s kubectl rollout status deployment/coredns -n kube-system -w --timeout=600s
    # Enable metrics-server
    sudo k8s enable metrics-server
    sudo k8s kubectl rollout status deployment/metrics-server -n kube-system -w --timeout=600s
    # Enable local-storage
    sudo k8s enable local-storage
    # Enable load-balancer with L2 mode
    sudo k8s enable load-balancer
    IPADDR=$(ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc')
    IFS='.' read -r a b c d <<< "$IPADDR"
    sudo k8s set load-balancer.cidrs=$a.$b.$c.$d-$a.$b.$c.$((d + 9)) load-balancer.l2-mode=true
    # Enable gateway API
    sudo k8s enable gateway

[private]
charmdev-ck8s-juju-bootstrap:
    # Bootstrap both LXD and Canonical K8s controllers and create default models
    juju bootstrap localhost lxd
    juju add-model --config logging-config="<root>=WARNING; unit=DEBUG" \
                   --config update-status-hook-interval="60m" welcome-lxd
    sudo k8s config | juju add-k8s ck8s --client
    juju bootstrap ck8s ck8s
    juju add-model --config logging-config="<root>=WARNING; unit=DEBUG" \
                   --config update-status-hook-interval="60m" welcome-k8s

[private]
charmdev-ck8s-export-kubeconfig:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p $HOME/.kube
    MACHINE=$(hostname | grep -oE '(kuma|inu|neko)$')
    # Export and rename to machine-specific names
    sudo k8s config | \
        yq ".clusters[0].name = \"${MACHINE}-cluster\" |
            .contexts[0].name = \"${MACHINE}\" |
            .contexts[0].context.cluster = \"${MACHINE}-cluster\" |
            .contexts[0].context.user = \"${MACHINE}-admin\" |
            .users[0].name = \"${MACHINE}-admin\" |
            .\"current-context\" = \"${MACHINE}\"" > /tmp/config-${MACHINE}-tmp
    # Merge or create
    if [ -f "$HOME/.kube/config" ]; then
        # Remove old entries for this machine, then merge
        yq "del(.clusters[] | select(.name == \"${MACHINE}-cluster\")) |
            del(.contexts[] | select(.name == \"${MACHINE}\")) |
            del(.users[] | select(.name == \"${MACHINE}-admin\"))" $HOME/.kube/config > /tmp/config-existing-tmp
        yq eval-all 'select(fileIndex == 0) *+ select(fileIndex == 1) | .current-context = "'"${MACHINE}"'"' /tmp/config-existing-tmp /tmp/config-${MACHINE}-tmp > $HOME/.kube/config
        rm -f /tmp/config-existing-tmp
    else
        mv /tmp/config-${MACHINE}-tmp $HOME/.kube/config
    fi
    rm -f /tmp/config-${MACHINE}-tmp
    echo "Kubeconfig merged for ${MACHINE}"

[private]
charmdev-ck8s-nuke:
    #!/usr/bin/env bash
    set -euo pipefail
    # Destroy Juju controllers and remove Juju/Canonical K8s
    sudo snap remove --purge juju || true
    sudo snap remove --purge k8s || true
    sudo snap remove --purge kubectl || true
    rm -rf ~/.local/share/juju ~/.cache/juju ~/.config/juju
    sudo rm -rf /var/snap/juju /var/snap/k8s
    sudo rm -rf /run/containerd
    # Remove only this machine's kubeconfig entries (preserve others)
    MACHINE=$(hostname | grep -oE '(kuma|inu|neko)$')
    if [ -f "$HOME/.kube/config" ]; then
        yq "del(.clusters[] | select(.name == \"${MACHINE}-cluster\")) |
            del(.contexts[] | select(.name == \"${MACHINE}\")) |
            del(.users[] | select(.name == \"${MACHINE}-admin\"))" $HOME/.kube/config > /tmp/config-cleaned
        mv /tmp/config-cleaned $HOME/.kube/config
        echo "Removed ${MACHINE} entries from kubeconfig"
    fi

# ====================================================================
# DEV TOOLING
# ====================================================================

charmdev-tools-setup:
    # Tools to support Juju + charmcraft workflow (jq + yq provided by nix)
    sudo snap install --classic charmcraft
    sudo snap install --classic rockcraft
    sudo snap install jhack --channel=latest/stable
    sudo snap install --classic astral-uv

charmdev-tools-nuke:
    # Remove all development tooling (jq + yq provided by nix, not snaps)
    sudo snap remove --purge charmcraft || true
    sudo snap remove --purge rockcraft || true
    sudo snap remove --purge jhack || true
    sudo snap remove --purge astral-uv || true
    sudo snap remove --purge just || true

# ====================================================================
# COMPOSITE RECIPES (use k8s=microk8s or k8s=ck8s)
# ====================================================================

# Setup charm development environment
# Usage: jg charmdev-setup              (defaults to microk8s)
#        jg k8s=ck8s charmdev-setup     (for Canonical K8s)
charmdev-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{k8s}}" = "microk8s" ]; then
        echo "Setting up MicroK8s charm development environment..."
        just -g charmdev-microk8s-install
        just -g charmdev-microk8s-setup
        just -g charmdev-microk8s-juju-bootstrap
        just -g charmdev-microk8s-export-kubeconfig
    elif [ "{{k8s}}" = "ck8s" ]; then
        echo "Setting up Canonical K8s charm development environment..."
        just -g charmdev-ck8s-install
        just -g charmdev-ck8s-setup
        just -g charmdev-ck8s-juju-bootstrap
        just -g charmdev-ck8s-export-kubeconfig
    else
        echo "Unknown k8s flavor: {{k8s}}. Use 'microk8s' or 'ck8s'"
        exit 1
    fi

# Nuke charm development environment
# Usage: jg charmdev-nuke              (defaults to microk8s)
#        jg k8s=ck8s charmdev-nuke     (for Canonical K8s)
charmdev-nuke:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{k8s}}" = "microk8s" ]; then
        echo "Nuking MicroK8s charm development environment..."
        just -g charmdev-microk8s-nuke
    elif [ "{{k8s}}" = "ck8s" ]; then
        echo "Nuking Canonical K8s charm development environment..."
        just -g charmdev-ck8s-nuke
    else
        echo "Unknown k8s flavor: {{k8s}}. Use 'microk8s' or 'ck8s'"
        exit 1
    fi

# ====================================================================
# ISTIO TESTER RECIPES
# ====================================================================

# Setup Istio test environment with bookinfo sample apps
# Usage: jg istio-tester-setup 2/edge
#        jg istio-tester-setup latest/edge
istio-tester-setup channel:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Setting up Istio test environment with channel: {{channel}}"

    # Create the istio-test model
    juju add-model istio-test

    # Deploy Istio charms from the specified channel
    juju deploy istio-k8s istio --channel={{channel}} --trust
    juju deploy istio-beacon-k8s beacon --channel={{channel}} --trust
    juju deploy istio-ingress-k8s ingress --channel={{channel}} --trust

    # Deploy bookinfo sample apps from latest/edge
    juju deploy bookinfo-productpage-k8s productpage --channel=latest/stable --trust
    juju deploy bookinfo-details-k8s details --channel=latest/stable --trust

    # Integrate the charms
    juju integrate productpage:details details:details
    juju integrate productpage:service-mesh beacon:service-mesh
    juju integrate details:service-mesh beacon:service-mesh
    juju integrate productpage:ingress ingress:ingress

    echo ""
    echo "Istio test environment setup complete!"
    echo "  - Model: istio-test"
    echo "  - Istio channel: {{channel}}"
    echo "  - Bookinfo apps: latest/edge"

# Nuke Istio test environment
# Usage: jg istio-tester-nuke
istio-tester-nuke:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Nuking Istio test environment..."
    juju destroy-model istio-test --force --destroy-storage --no-prompt
    echo "Istio test environment nuked."
