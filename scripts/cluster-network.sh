#!/usr/bin/env bash
set -euo pipefail

# Сетевая подготовка для lab k3s: 1 control plane + 2 worker.
# Запускать на КАЖДОЙ VM с уникальным --role, --ip и --name.
#
# Пример (подставьте свои IP):
#   CP:  ./cluster-network.sh --role cp --ip 192.168.200.10 --name k8s-control-plane
#   W1:  ./cluster-network.sh --role wn --ip 192.168.200.11 --name k8s-worker-1
#   W2:  ./cluster-network.sh --role wn --ip 192.168.200.12 --name k8s-worker-2

ROLE=""
SELF_IP=""
NODE_NAME=""
CP_IP="${CP_IP:-192.168.200.10}"
WORKER1_IP="${WORKER1_IP:-192.168.200.11}"
WORKER2_IP="${WORKER2_IP:-192.168.200.12}"
CP_HOST="k8s-control-plane"
WORKER1_HOST="k8s-worker-1"
WORKER2_HOST="k8s-worker-2"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)        ROLE="$2"; shift 2 ;;
    --ip)          SELF_IP="$2"; shift 2 ;;
    --name)        NODE_NAME="$2"; shift 2 ;;
    --cp-ip)       CP_IP="$2"; shift 2 ;;
    --worker1-ip)  WORKER1_IP="$2"; shift 2 ;;
    --worker2-ip)  WORKER2_IP="$2"; shift 2 ;;
    --cp-host)     CP_HOST="$2"; shift 2 ;;
    --worker1-host) WORKER1_HOST="$2"; shift 2 ;;
    --worker2-host) WORKER2_HOST="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$ROLE" || -z "$SELF_IP" || -z "$NODE_NAME" ]]; then
  cat <<'EOF'
Usage:
  ./cluster-network.sh --role cp|wn --ip SELF_IP --name HOSTNAME \
    [--cp-ip IP] [--worker1-ip IP] [--worker2-ip IP]

Пример (3 VM):
  CP: ./cluster-network.sh --role cp --ip 192.168.200.10 --name k8s-control-plane
  W1: ./cluster-network.sh --role wn --ip 192.168.200.11 --name k8s-worker-1
  W2: ./cluster-network.sh --role wn --ip 192.168.200.12 --name k8s-worker-2
EOF
  exit 1
fi

sudo hostnamectl set-hostname "$NODE_NAME"

sudo tee /etc/hosts >/dev/null <<EOF
127.0.0.1 localhost
${SELF_IP}  ${NODE_NAME}
${CP_IP}    ${CP_HOST}
${WORKER1_IP}  ${WORKER1_HOST}
${WORKER2_IP}  ${WORKER2_HOST}
EOF

sudo swapoff -a || true
sudo sed -i '/ swap / s/^/#/' /etc/fstab

if command -v ufw &>/dev/null; then
  sudo ufw allow 22/tcp
  if [[ "$ROLE" == "cp" ]]; then
    sudo ufw allow 6443/tcp comment 'k3s API'
    sudo ufw allow 10250/tcp comment 'kubelet'
    sudo ufw allow 8472/udp comment 'flannel vxlan'
    sudo ufw allow 80,443/tcp
  fi
  sudo ufw --force enable || true
fi

echo "Network configured for ${NODE_NAME} (${ROLE}, ${SELF_IP})"
for host in "$CP_HOST" "$WORKER1_HOST" "$WORKER2_HOST"; do
  if ping -c1 -W2 "$host" >/dev/null 2>&1; then
    echo "Reachable: $host"
  else
    echo "WARN: $host unreachable (проверьте, что все VM в одной сети)"
  fi
done
