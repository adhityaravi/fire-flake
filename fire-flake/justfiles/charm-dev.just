# Justfile for setting up and nuking a charm development environment

default:
    just --summary

# --------------------------------------------------------------------
# CORE RECIPES
# --------------------------------------------------------------------

install-core-snaps:
    # Install Juju and MicroK8s
    sudo snap install juju --channel=3.6/stable
    sudo snap install microk8s --channel=1.32/stable --classic
    # sudo snap install microk8s --channel=1.32-strict/stable
    sudo snap alias microk8s.kubectl kubectl
    sudo snap alias microk8s.kubectl k

microk8s-setup:
    # Configure MicroK8s and enable required addons
    sudo usermod -a -G microk8s $USER
    sudo usermod -a -G snap_microk8s $USER
    microk8s status --wait-ready
    sudo microk8s enable metrics-server
    sudo microk8s kubectl rollout status deployments/metrics-server -n kube-system -w --timeout=600s
    sudo microk8s enable dns
    sudo microk8s kubectl rollout status deployments/coredns -n kube-system -w --timeout=600s
    sudo microk8s enable rbac
    sudo microk8s enable hostpath-storage
    sudo microk8s kubectl rollout status deployments/hostpath-provisioner -n kube-system -w --timeout=600s
    IPADDR=$(ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc'); sudo microk8s enable metallb:$IPADDR-$IPADDR
    sudo microk8s kubectl rollout status daemonset.apps/speaker -n metallb-system -w --timeout=600s
    sudo microk8s enable registry
    sudo microk8s kubectl rollout status deployment.apps/registry -n container-registry -w --timeout=600s

juju-bootstrap:
    # Bootstrap both LXD and MicroK8s controllers and create default models
    juju bootstrap localhost lxd
    juju add-model --config logging-config="<root>=WARNING; unit=DEBUG" \
                   --config update-status-hook-interval="60m" welcome-lxd
    microk8s config | juju add-k8s mcrk8s --client
    juju bootstrap mcrk8s mcrk8s
    juju add-model --config logging-config="<root>=WARNING; unit=DEBUG" \
                   --config update-status-hook-interval="60m" welcome-k8s

export-kubeconfig:
    # Save kubeconfig to user's home
    mkdir -p $HOME/.kube
    microk8s config > $HOME/.kube/config

# --------------------------------------------------------------------
# DEV TOOLING
# --------------------------------------------------------------------

install-dev-snaps:
    # Tools to support Juju + charmcraft workflow
    sudo snap install --classic charmcraft
    sudo snap install --classic rockcraft
    sudo snap install jhack --channel=latest/stable
    sudo snap install --classic astral-uv
    sudo snap install yq

# --------------------------------------------------------------------
# NUKE RECIPES
# --------------------------------------------------------------------

nuke-core-snaps:
    # Destroy Juju controllers and remove Juju/MicroK8s
    sudo snap remove --purge juju || true
    sudo snap remove --purge microk8s || true

    rm -rf ~/.local/share/juju ~/.cache/juju ~/.config/juju
    sudo rm -rf /var/snap/juju /var/snap/microk8s
    rm -f ~/.kube/config

nuke-dev-snaps:
    # Remove all development tooling
    sudo snap remove --purge charmcraft || true
    sudo snap remove --purge rockcraft || true
    sudo snap remove --purge jhack || true
    sudo snap remove --purge astral-uv || true
    sudo snap remove --purge yq || true
    sudo snap remove --purge just || true

# --------------------------------------------------------------------
# COMPOSITE RECIPES
# --------------------------------------------------------------------

setup-charm-dev:
    just -g install-core-snaps
    just -g microk8s-setup
    just -g juju-bootstrap
    just -g export-kubeconfig

setup-charm-dev-tools:
    just -g install-dev-snaps

nuke-charm-dev:
    just -g nuke-core-snaps

nuke-charm-dev-tools:
    just -g nuke-dev-snaps
