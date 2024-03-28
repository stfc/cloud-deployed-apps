#!/bin/bash

echo "getting password from k8s - make sure you have run ./deploy"
ARGOCD_PWD=$(kubectl -n argocd get secrets argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "THIS IS THE ARGOCD PASSWORD: $ARGOCD_PWD"
