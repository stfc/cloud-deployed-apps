#!/bin/bash

set -euo pipefail

if [ -z "$1" ]; then
  echo "Please provide the filepath to the SOPS private key"
  echo "Usage: $0 <sops-private key filepath>"
  exit 1
fi

# Set the directory containing the SOPS-encrypted files
SOPS_PRIVATE_KEY_FP="$1"

# Check if the SOPS private key file exists
if [ -z "$SOPS_PRIVATE_KEY_FP" ]; then
  echo "SOPS private key file not found."
  exit 1
fi

kubectl apply -f argocd-ns.yaml
kubectl -n argocd create secret generic helm-secrets-private-keys --from-file=key.txt="$SOPS_PRIVATE_KEY_FP" --namespace argocd

echo "Argo CD secret "helm-secrets-private-keys" created successfully in the argocd namespace."
