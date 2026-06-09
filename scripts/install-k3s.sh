#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   Master:  ./install-k3s.sh server [--name NODE_NAME]
#   Worker:  ./install-k3s.sh agent --url https://MASTER_IP:6443 --token TOKEN [--name NODE_NAME]

ROLE="${1:-}"
shift || true

K3S_URL=""
K3S_TOKEN=""
NODE_NAME="$(hostname -s)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)   K3S_URL="$2"; shift 2 ;;
    --token) K3S_TOKEN="$2"; shift 2 ;;
    --name)  NODE_NAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

install_prereqs() {
  sudo swapoff -a || true
  sudo sed -i '/ swap / s/^/#/' /etc/fstab
}

case "$ROLE" in
  server)
    install_prereqs
    curl -sfL https://get.k3s.io | sh -s - server \
      --write-kubeconfig-mode 644 \
      --node-name "$NODE_NAME" \
      --disable traefik
    echo
    echo "Node token (save for workers):"
    sudo cat /var/lib/rancher/k3s/server/node-token
    echo
    echo "Kubeconfig: /etc/rancher/k3s/k3s.yaml"
    ;;
  agent)
    if [[ -z "$K3S_URL" || -z "$K3S_TOKEN" ]]; then
      echo "Worker requires --url and --token"
      exit 1
    fi
    install_prereqs
    curl -sfL https://get.k3s.io | K3S_URL="$K3S_URL" K3S_TOKEN="$K3S_TOKEN" \
      sh -s - agent --node-name "$NODE_NAME"
    ;;
  *)
    echo "Usage:"
    echo "  $0 server [--name NODE_NAME]"
    echo "  $0 agent --url https://MASTER_IP:6443 --token TOKEN [--name NODE_NAME]"
    exit 1
    ;;
esac

echo "Done. Check nodes: sudo k3s kubectl get nodes -o wide"
