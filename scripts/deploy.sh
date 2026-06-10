#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Applying manifests"
kubectl apply -f "$ROOT/Namespace.yaml"
kubectl apply -f "$ROOT/ResourceQuota.yaml"
kubectl apply -f "$ROOT/Deployment.yaml"
kubectl apply -f "$ROOT/Service.yaml"
kubectl apply -f "$ROOT/HPA.yaml"
kubectl apply -f "$ROOT/PDB.yaml"
kubectl apply -f "$ROOT/NetworkPolicy.yaml"
kubectl apply -f "$ROOT/Ingress.yaml"

if [ -d "$ROOT/mesh" ]; then
  echo "==> Applying mesh policies"
  kubectl apply -f "$ROOT/mesh/"
fi

echo "==> Restarting deployment to inject sidecar"
kubectl rollout restart deployment/http-app -n ourcoolnamespace
kubectl rollout status deployment/http-app -n ourcoolnamespace --timeout=300s

echo "==> Status"
kubectl -n ourcoolnamespace get pods,svc,ingress,hpa,pdb
