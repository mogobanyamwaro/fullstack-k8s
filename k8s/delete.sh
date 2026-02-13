#!/bin/bash
set -e

# Run from k8s directory so overlays path is correct
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV=${1:-}

case $ENV in
  dev|staging|prod)
    echo "🗑️  Deleting Kustomization for $ENV (namespace fullstack-$ENV)..."
    kubectl delete -k overlays/$ENV --ignore-not-found=true
    echo "✅ $ENV resources deleted!"
    ;;
  *)
    echo "Usage: ./delete.sh [dev|staging|prod]"
    echo "  dev     - delete fullstack-dev"
    echo "  staging - delete fullstack-staging"
    echo "  prod    - delete fullstack-prod"
    exit 1
    ;;
esac
