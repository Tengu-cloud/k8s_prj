#!/usr/bin/env bash
set -euo pipefail

ISTIO_VERSION="${ISTIO_VERSION:-1.24.2}"
ISTIO_PROFILE="${ISTIO_PROFILE:-minimal}"
INSTALL_DIR="${INSTALL_DIR:-/tmp/istio-${ISTIO_VERSION}}"

if ! command -v istioctl >/dev/null 2>&1; then
  echo "==> Downloading istioctl ${ISTIO_VERSION}"
  curl -fsSL "https://istio.io/downloadIstio" | ISTIO_VERSION="${ISTIO_VERSION}" sh -
  export PATH="${INSTALL_DIR}/bin:${PATH}"
fi

echo "==> Cleaning up istio-ingressgateway from a previous default install (if any)"
kubectl delete deployment,service istio-ingressgateway -n istio-system --ignore-not-found

echo "==> Installing Istio control plane (profile=${ISTIO_PROFILE})"
istioctl install -y --set profile="${ISTIO_PROFILE}" \
  --set values.global.proxy.resources.requests.cpu=50m \
  --set values.global.proxy.resources.requests.memory=64Mi \
  --set values.global.proxy.resources.limits.cpu=200m \
  --set values.global.proxy.resources.limits.memory=256Mi

echo "==> Waiting for istio-system pods"
kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s

kubectl get pods -n istio-system
