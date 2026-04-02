# Justfile for Maki infrastructure setup on Canonical K8s
# Usage: jg maki-setup, jg maki-nuke

# ====================================================================
# CANONICAL K8S — INSTALL & BOOTSTRAP
# ====================================================================

maki-k8s-install:
    # Install Canonical K8s
    sudo snap install k8s --classic --channel=1.32-classic/stable

maki-k8s-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    # Bootstrap Canonical K8s and enable required features
    sudo k8s bootstrap
    sudo k8s status --wait-ready
    # DNS (CoreDNS)
    sudo k8s enable dns
    sudo k8s kubectl rollout status deployment/coredns -n kube-system -w --timeout=600s
    # Metrics server
    sudo k8s enable metrics-server
    sudo k8s kubectl rollout status deployment/metrics-server -n kube-system -w --timeout=600s
    # Local storage
    sudo k8s enable local-storage
    # Load balancer (L2 mode)
    sudo k8s enable load-balancer
    IPADDR=$(ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc')
    IFS='.' read -r a b c d <<< "$IPADDR"
    sudo k8s set load-balancer.cidrs=$a.$b.$c.$d-$a.$b.$c.$((d + 9)) load-balancer.l2-mode=true
    # Gateway API
    sudo k8s enable gateway

maki-k8s-export-kubeconfig:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p $HOME/.kube
    MACHINE=$(hostname)
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
        yq "del(.clusters[] | select(.name == \"${MACHINE}-cluster\")) |
            del(.contexts[] | select(.name == \"${MACHINE}\")) |
            del(.users[] | select(.name == \"${MACHINE}-admin\"))" $HOME/.kube/config > /tmp/config-existing-tmp
        yq eval-all 'select(fileIndex == 0) *+ select(fileIndex == 1) | .current-context = "'"${MACHINE}"'"' /tmp/config-existing-tmp /tmp/config-${MACHINE}-tmp > $HOME/.kube/config
        rm -f /tmp/config-existing-tmp
    else
        mv /tmp/config-${MACHINE}-tmp $HOME/.kube/config
    fi
    rm -f /tmp/config-${MACHINE}-tmp
    chmod 600 $HOME/.kube/config
    echo "Kubeconfig merged for ${MACHINE}"

# Full setup: install, bootstrap, export kubeconfig
maki-setup: maki-k8s-install maki-k8s-setup maki-k8s-export-kubeconfig
    @echo "Canonical K8s ready for Maki"

# ====================================================================
# MAKI NAMESPACE & GHCR AUTH
# ====================================================================

maki-namespace:
    kubectl create namespace maki --dry-run=client -o yaml | kubectl apply -f -

maki-ghcr-login:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Enter your GitHub PAT (read:packages scope):"
    read -rs GHCR_TOKEN
    kubectl create secret docker-registry ghcr-credentials \
        --namespace=maki \
        --docker-server=ghcr.io \
        --docker-username=$(git config user.name) \
        --docker-password="$GHCR_TOKEN" \
        --dry-run=client -o yaml | kubectl apply -f -
    # Patch default service account to use the secret
    kubectl patch serviceaccount default -n maki \
        -p '{"imagePullSecrets": [{"name": "ghcr-credentials"}]}'
    echo "GHCR credentials configured for maki namespace"

# ====================================================================
# NUKE
# ====================================================================

maki-k8s-nuke:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "This will remove Canonical K8s and all data. Are you sure? (y/N)"
    read -r confirm
    if [ "$confirm" != "y" ]; then
        echo "Aborted."
        exit 0
    fi
    sudo snap remove --purge k8s || true
    sudo rm -rf /var/snap/k8s
    sudo rm -rf /run/containerd
    # Remove this machine's kubeconfig entries
    MACHINE=$(hostname)
    if [ -f "$HOME/.kube/config" ]; then
        yq "del(.clusters[] | select(.name == \"${MACHINE}-cluster\")) |
            del(.contexts[] | select(.name == \"${MACHINE}\")) |
            del(.users[] | select(.name == \"${MACHINE}-admin\"))" $HOME/.kube/config > /tmp/config-cleaned
        mv /tmp/config-cleaned $HOME/.kube/config
        echo "Removed ${MACHINE} entries from kubeconfig"
    fi

# ====================================================================
# STATUS
# ====================================================================

maki-status:
    @echo "=== K8s ==="
    sudo k8s status
    @echo ""
    @echo "=== Maki Pods ==="
    kubectl get pods -n maki -o wide 2>/dev/null || echo "No maki namespace yet"
    @echo ""
    @echo "=== Maki Services ==="
    kubectl get svc -n maki 2>/dev/null || echo "No maki namespace yet"
