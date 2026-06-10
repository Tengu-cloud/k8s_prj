#!/usr/bin/env bash
# Справочник команд для развёртывания k3s на 3 VM.
# Скопируйте репозиторий на каждую VM и выполните соответствующий блок.

CP_IP="${CP_IP:-192.168.1.10}"
W1_IP="${W1_IP:-192.168.1.11}"
W2_IP="${W2_IP:-192.168.1.12}"

cat <<EOF
=== k3s cluster: k8s-control-plane + k8s-worker-1 + k8s-worker-2 ===

Требования на каждой VM:
  - Ubuntu 22.04/24.04 (или другой Linux с systemd)
  - 2+ CPU, 2+ GB RAM (control plane: 4 GB рекомендуется)
  - Статические IP в одной L2/L3 сети
  - SSH-доступ

--- 1. На ВСЕХ трёх VM: сетевая подготовка ---

  # k8s-control-plane:
  sudo bash scripts/cluster-network.sh --role cp --ip ${CP_IP} --name k8s-control-plane \\
    --cp-ip ${CP_IP} --worker1-ip ${W1_IP} --worker2-ip ${W2_IP}

  # k8s-worker-1:
  sudo bash scripts/cluster-network.sh --role wn --ip ${W1_IP} --name k8s-worker-1 \\
    --cp-ip ${CP_IP} --worker1-ip ${W1_IP} --worker2-ip ${W2_IP}

  # k8s-worker-2:
  sudo bash scripts/cluster-network.sh --role wn --ip ${W2_IP} --name k8s-worker-2 \\
    --cp-ip ${CP_IP} --worker1-ip ${W1_IP} --worker2-ip ${W2_IP}

--- 2. Только на k8s-control-plane: установка server ---

  sudo bash scripts/install-k3s.sh server --ip ${CP_IP} --name k8s-control-plane

  Сохраните выведенный node-token.

--- 3. На k8s-worker-1 и k8s-worker-2: установка agent ---

  # worker-1:
  sudo bash scripts/install-k3s.sh agent \\
    --url https://${CP_IP}:6443 \\
    --token <NODE_TOKEN> \\
    --ip ${W1_IP} --name k8s-worker-1

  # worker-2:
  sudo bash scripts/install-k3s.sh agent \\
    --url https://${CP_IP}:6443 \\
    --token <NODE_TOKEN> \\
    --ip ${W2_IP} --name k8s-worker-2

--- 4. Проверка (на control plane) ---

  sudo k3s kubectl get nodes -o wide

  Ожидаемый результат: 3 ноды в статусе Ready.

--- 5. Kubeconfig для kubectl с вашего ПК ---

  sudo cat /etc/rancher/k3s/k3s.yaml
  # Замените 127.0.0.1 на ${CP_IP}, сохраните как ~/.kube/config

--- 6. (Опционально) Ingress для манифестов проекта ---

  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml
  # Затем с control plane или ПК:
  bash scripts/deploy.sh

EOF
