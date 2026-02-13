#!/bin/bash
# Reset a node so it can rejoin (e.g. was control plane, or join failed).
#
# Usage: ./reset-node.sh <worker-ip-or-hostname> [path/to/terraform.pem]
# Example: ./reset-node.sh 54.81.73.199

KEY="${2:-../terraform.pem}"
HOST="${1:?Usage: $0 <worker-ip> [key-path]}"
BASE="$(cd "$(dirname "$0")" && pwd)"
KEY_PATH="$(cd "$BASE" && cd "$(dirname "$KEY")" && pwd)/$(basename "$KEY")"

echo "Resetting $HOST..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$HOST "sudo kubeadm reset -f --ignore-preflight-errors=all"
echo "Done. Run prep.sh on this node, then kubeadm join (from master)."
