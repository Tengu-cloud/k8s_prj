#!/usr/bin/env bash
set -euo pipefail

# Общая сетевая подготовка для lab из 3 VM (1 CP + 2 WN).
# Запускать на КАЖДОЙ VM с уникальным --role и --name.
#
# Usage:
#   CP:  ./cluster-network.sh --role cp  --ip 192.168.1.10 --name k8s-cp
#   WN1: ./cluster-network.sh --role wn  --ip 192.168.1.11 --name k8s-wn1 --cp-ip 192.168.1.10
#   WN2: ./cluster-network.sh --role wn  --ip 192.168.1.12 --name k8s-wn2 --cp-ip 192.168.1.10

ROLE=""
SELF_IP=""
NODE_NAME=""
CP_IP="192.168.1.10"
WN1_IP="192.168.1.11"
WN2_IP="192.168.1.12"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)  ROLE="$2"; shift 2 ;;
    --ip)    SELF_IP="$2"; shift 2 ;;
    --name)  NODE_NAME="$2"; shift 2 ;;
    --cp-ip) CP_IP="$2"; shift 2 ;;
    --wn1-ip) WN1_IP="$2"; shift 2 ;;
    --wn2-ip) WN2_IP="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$ROLE" || -z "$SELF_IP" || -z "$NODE_NAME" ]]; then
  echo "Usage: $0 --role cp|wn --ip SELF_IP --name HOSTNAME [--cp-ip IP] [--wn1-ip IP] [--wn2-ip IP]"
  exit 1
fi

sudo hostnamectl set-hostname "$NODE_NAME"

sudo tee /etc/hosts >/dev/null <<EOF
127.0.0.1 localhost
${SELF_IP} ${NODE_NAME}
${CP_IP}  k8s-cp
${WN1_IP}  k8s-wn1
${WN2_IP}  k8s-wn2
EOF

sudo swapoff -a || true
sudo sed -i '/ swap / s/^/#/' /etc/fstab

if command -v ufw &>/dev/null; then
  sudo ufw allow 22/tcp
  if [[ "$ROLE" == "cp" ]]; then
    sudo ufw allow 80,443/tcp
    sudo ufw allow from "${CP_IP%.*}.0/24"
  fi
  sudo ufw --force enable || true
fi

echo "Network configured for ${NODE_NAME} (${ROLE}, ${SELF_IP})"
ping -c1 -W2 k8s-cp >/dev/null && echo "Reachable: k8s-cp" || echo "WARN: k8s-cp unreachable"
