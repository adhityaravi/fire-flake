# Justfile for setting up and nuking a charm development environment
# Usage: jg k8s=ck8s charmdev-setup  (or k8s=microk8s, which is the default)

# Default Kubernetes flavor: "microk8s" or "ck8s"
k8s := "microk8s"

# ====================================================================
# MICROK8S RECIPES
# ====================================================================

[private]
charmdev-microk8s-install:
    # Install Juju and MicroK8s
    sudo snap install juju --channel=3.6/stable
    sudo snap install microk8s --channel=1.32/stable --classic
    sudo snap alias microk8s.kubectl kubectl
    sudo snap alias microk8s.kubectl k

[private]
charmdev-microk8s-setup:
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
    IPADDR=$(ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc'); IFS='.' read -r a b c d <<< "$IPADDR"; sudo microk8s enable metallb:$IPADDR-$a.$b.$c.$((d + 9))
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
    # Save kubeconfig to user's home
    mkdir -p $HOME/.kube
    sudo microk8s config > $HOME/.kube/config

[private]
charmdev-microk8s-nuke:
    # Destroy Juju controllers and remove Juju/MicroK8s
    sudo snap remove --purge juju || true
    sudo snap remove --purge microk8s || true
    rm -rf ~/.local/share/juju ~/.cache/juju ~/.config/juju
    sudo rm -rf /var/snap/juju /var/snap/microk8s
    sudo rm -rf /run/containerd
    rm -f ~/.kube/config

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
    IPADDR=$(ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc'); IFS='.' read -r a b c d <<< "$IPADDR"; sudo k8s set load-balancer.cidrs=$a.$b.$c.$d-$a.$b.$c.$((d + 9)) load-balancer.l2-mode=true
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
    # Save kubeconfig to user's home
    mkdir -p $HOME/.kube
    sudo k8s config > $HOME/.kube/config

[private]
charmdev-ck8s-nuke:
    # Destroy Juju controllers and remove Juju/Canonical K8s
    sudo snap remove --purge juju || true
    sudo snap remove --purge k8s || true
    sudo snap remove --purge kubectl || true
    rm -rf ~/.local/share/juju ~/.cache/juju ~/.config/juju
    sudo rm -rf /var/snap/juju /var/snap/k8s
    sudo rm -rf /run/containerd
    rm -f ~/.kube/config

# ====================================================================
# DEV TOOLING
# ====================================================================

charmdev-tools-setup:
    # Tools to support Juju + charmcraft workflow
    sudo snap install --classic charmcraft
    sudo snap install --classic rockcraft
    sudo snap install jhack --channel=latest/stable
    sudo snap install --classic astral-uv
    sudo snap install yq
    sudo snap install jq

charmdev-tools-nuke:
    # Remove all development tooling
    sudo snap remove --purge charmcraft || true
    sudo snap remove --purge rockcraft || true
    sudo snap remove --purge jhack || true
    sudo snap remove --purge astral-uv || true
    sudo snap remove --purge yq || true
    sudo snap remove --purge jq || true
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
