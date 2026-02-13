#!/bin/bash
# One-shot cluster setup. Run from laptop. Requires: terraform.pem, 3 EC2 IPs.
#
# Usage: ./setup.sh [path/to/terraform.pem]
#
# Before running: cd terraform && terraform output
# Then edit CP, W1, W2 below (control plane first, then workers).

set -e
KEY="${1:-../terraform.pem}"
BASE="$(cd "$(dirname "$0")" && pwd)"
KEY_PATH="$(cd "$BASE" && cd "$(dirname "$KEY")" && pwd)/$(basename "$KEY")"

# EDIT: Set from terraform output instance_public_ips (index 0=control plane, 1-2=workers)
CP=""
W1=""
W2=""

[ -z "$CP" ] && { echo "Edit CP, W1, W2 in this script (from terraform output)"; exit 1; }

run() { ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "ubuntu@$1" "$2"; }
copy_run() {
  scp -i "$KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$BASE/$1" "ubuntu@$2:/tmp/"
  run "$2" "chmod +x /tmp/$1 && /tmp/$1 $3"
}

echo "=== 1. Prep all 3 nodes ==="
copy_run prep.sh "$CP" "master-node"
copy_run prep.sh "$W1" "worker-node-1"
copy_run prep.sh "$W2" "worker-node-2"

echo ""
echo "=== 2. Init control plane + Flannel ==="
copy_run init-master.sh "$CP"

echo ""
echo "=== 3. Get join command ==="
JOIN=$(run "$CP" "sudo kubeadm token create --print-join-command")
echo "Join: $JOIN"

echo ""
echo "=== 4. Join workers ==="
run "$W1" "sudo $JOIN"
run "$W2" "sudo $JOIN"

echo ""
echo "=== 5. Wait and verify ==="
run "$CP" "sleep 45 && kubectl get nodes && kubectl get pods -A"

echo ""
echo "=== Done ==="
