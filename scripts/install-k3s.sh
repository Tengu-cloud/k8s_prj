#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   Control plane:
#     ./install-k3s.sh server --ip 192.168.200.10 --name k8s-control-plane
#   Worker:
#     ./install-k3s.sh agent --url https://192.168.200.10:6443 --token TOKEN \
#       --ip 192.168.200.11 --name k8s-worker-1

ROLE="${1:-}"
shift || true

K3S_URL=""
K3S_TOKEN=""
NODE_IP=""
NODE_NAME="$(hostname -s)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)   K3S_URL="$2"; shift 2 ;;
    --token) K3S_TOKEN="$2"; shift 2 ;;
    --ip)    NODE_IP="$2"; shift 2 ;;
    --name)  NODE_NAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

install_prereqs() {
  sudo swapoff -a || true
  sudo sed -i '/ swap / s/^/#/' /etc/fstab
}

SERVER_ARGS=(
  --write-kubeconfig-mode 644
  --node-name "$NODE_NAME"
  --disable traefik
)

AGENT_ARGS=(--node-name "$NODE_NAME")

if [[ -n "$NODE_IP" ]]; then
  SERVER_ARGS+=(--node-ip "$NODE_IP" --advertise-address "$NODE_IP" --tls-san "$NODE_IP" --tls-san "$NODE_NAME")
  AGENT_ARGS+=(--node-ip "$NODE_IP")
fi

case "$ROLE" in
  server)
    install_prereqs
    curl -sfL https://get.k3s.io | sh -s - server "${SERVER_ARGS[@]}"
    echo
    echo "=== Сохраните token для worker-нод ==="
    sudo cat /var/lib/rancher/k3s/server/node-token
    echo
    echo "Kubeconfig: /etc/rancher/k3s/k3s.yaml"
    echo "Проверка: sudo k3s kubectl get nodes"
    ;;
  agent)
    if [[ -z "$K3S_URL" || -z "$K3S_TOKEN" ]]; then
      echo "Worker requires --url and --token"
      exit 1
    fi
    install_prereqs
    curl -sfL https://get.k3s.io | K3S_URL="$K3S_URL" K3S_TOKEN="$K3S_TOKEN" \
      sh -s - agent "${AGENT_ARGS[@]}"
    ;;
  *)
    cat <<'EOF'
Usage:
  Control plane:
    ./install-k3s.sh server --ip CP_IP [--name k8s-control-plane]
  Worker:
    ./install-k3s.sh agent --url https://CP_IP:6443 --token TOKEN \
      --ip WORKER_IP [--name k8s-worker-1]
EOF
    exit 1
    ;;
esac

echo "Done. На control plane: sudo k3s kubectl get nodes -o wide"
