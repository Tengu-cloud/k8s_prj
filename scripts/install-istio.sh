#!/usr/bin/env bash
set -euo pipefail

ISTIO_VERSION="${ISTIO_VERSION:-1.24.2}"
INSTALL_DIR="${INSTALL_DIR:-/tmp/istio-${ISTIO_VERSION}}"

if ! command -v istioctl >/dev/null 2>&1; then
  echo "==> Downloading istioctl ${ISTIO_VERSION}"
  curl -fsSL "https://istio.io/downloadIstio" | ISTIO_VERSION="${ISTIO_VERSION}" sh -
  export PATH="${INSTALL_DIR}/bin:${PATH}"
fi

echo "==> Installing Istio control plane"
istioctl install -y --set profile=default \
  --set values.global.proxy.resources.requests.cpu=50m \
  --set values.global.proxy.resources.requests.memory=64Mi \
  --set values.global.proxy.resources.limits.cpu=200m \
  --set values.global.proxy.resources.limits.memory=256Mi

echo "==> Waiting for istio-system pods"
kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s

kubectl get pods -n istio-system
