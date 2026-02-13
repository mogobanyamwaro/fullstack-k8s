#!/bin/bash
# Verify cluster: kubectl get nodes and pods. Run from laptop.
#
# Usage: ./verify-cluster.sh [path/to/terraform.pem]
# Edit CP below (control plane public IP from terraform output).

KEY="${1:-../terraform.pem}"
BASE="$(cd "$(dirname "$0")" && pwd)"
KEY_PATH="$(cd "$BASE" && cd "$(dirname "$KEY")" && pwd)/$(basename "$KEY")"

# EDIT: Control plane public IP
CP=""

[ -z "$CP" ] && { echo "Edit CP in this script (control plane public IP from terraform output)"; exit 1; }

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$CP "kubectl get nodes -o wide && echo '---' && kubectl get pods -A"
