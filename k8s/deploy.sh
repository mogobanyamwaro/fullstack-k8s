#!/bin/bash
set -e

# Run from k8s directory so overlays path is correct
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Try to get IP for /etc/hosts (ingress LoadBalancer or first node)
get_cluster_ip() {
  local ip
  ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return
  ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return
  ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return
  ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return
  echo ""
}

# Get NodePort for ingress-nginx if present (e.g. 30814)
get_ingress_node_port() {
  kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null || true
}

ENV=${1:-dev}

case $ENV in
  dev|staging|prod)
    echo "🚀 Deploying to $ENV..."
    kubectl apply -k overlays/$ENV
    echo "✅ $ENV deployed!"
    echo ""
    CLUSTER_IP=$(get_cluster_ip)
    NODE_PORT=$(get_ingress_node_port)
    PORT_SUFFIX=""
    [[ -n "$NODE_PORT" ]] && PORT_SUFFIX=":${NODE_PORT}"

    case $ENV in
      dev)
        HOSTS="frontend.dev.fullstack-app.local backend.dev.fullstack-app.local"
        echo "1. Add the ingress hosts to your machine (run once, use the IP that reaches your cluster):"
        if [[ -n "$CLUSTER_IP" ]]; then
          echo "   echo \"${CLUSTER_IP} ${HOSTS}\" | sudo tee -a /etc/hosts"
        else
          echo "   echo \"<CLUSTER_IP> ${HOSTS}\" | sudo tee -a /etc/hosts"
          echo "   (Replace <CLUSTER_IP> with your node IP or ingress LoadBalancer IP; run: kubectl get nodes -o wide)"
        fi
        echo ""
        echo "2. Open in browser:"
        echo "   Frontend:    http://frontend.dev.fullstack-app.local${PORT_SUFFIX}"
        echo "   Backend:     http://backend.dev.fullstack-app.local${PORT_SUFFIX}"
        echo "   Backend API: http://backend.dev.fullstack-app.local${PORT_SUFFIX}/todos"
        ;;
      staging)
        HOSTS="frontend.staging.fullstack-app.local backend.staging.fullstack-app.local"
        echo "1. Add the ingress hosts to your machine (run once, use the IP that reaches your cluster):"
        if [[ -n "$CLUSTER_IP" ]]; then
          echo "   echo \"${CLUSTER_IP} ${HOSTS}\" | sudo tee -a /etc/hosts"
        else
          echo "   echo \"<CLUSTER_IP> ${HOSTS}\" | sudo tee -a /etc/hosts"
          echo "   (Replace <CLUSTER_IP> with your node IP or ingress LoadBalancer IP; run: kubectl get nodes -o wide)"
        fi
        echo ""
        echo "2. Open in browser:"
        echo "   Frontend:    http://frontend.staging.fullstack-app.local${PORT_SUFFIX}"
        echo "   Backend:     http://backend.staging.fullstack-app.local${PORT_SUFFIX}"
        echo "   Backend API: http://backend.staging.fullstack-app.local${PORT_SUFFIX}/todos"
        ;;
      prod)
        HOSTS="frontend.prod.fullstack-app.local backend.prod.fullstack-app.local backend.fullstack-app.local"
        echo "1. Add the ingress hosts to your machine (run once, use the IP that reaches your cluster):"
        if [[ -n "$CLUSTER_IP" ]]; then
          echo "   echo \"${CLUSTER_IP} ${HOSTS}\" | sudo tee -a /etc/hosts"
        else
          echo "   echo \"<CLUSTER_IP> ${HOSTS}\" | sudo tee -a /etc/hosts"
          echo "   (Replace <CLUSTER_IP> with your node IP or ingress LoadBalancer IP; run: kubectl get nodes -o wide)"
        fi
        echo ""
        echo "2. Open in browser:"
        echo "   Frontend:    http://frontend.prod.fullstack-app.local${PORT_SUFFIX}"
        echo "   Backend:     http://backend.prod.fullstack-app.local${PORT_SUFFIX}"
        echo "   Backend API: http://backend.prod.fullstack-app.local${PORT_SUFFIX}/todos"
        ;;
    esac
    echo ""
    echo "Namespace: fullstack-$ENV"
    [[ -n "$NODE_PORT" ]] && echo "(NodePort $NODE_PORT – if using LoadBalancer you may not need the port in the URL.)"
    ;;
  *)
    echo "Usage: ./deploy.sh [dev|staging|prod]"
    echo "  dev     - fullstack-dev   (frontend.dev.fullstack-app.local, backend.dev.fullstack-app.local)"
    echo "  staging - fullstack-staging"
    echo "  prod    - fullstack-prod  (frontend.prod.fullstack-app.local, backend.prod.fullstack-app.local)"
    exit 1
    ;;
esac
