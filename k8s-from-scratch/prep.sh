#!/bin/bash
set -e
# Run on ALL 3 nodes. Optional: ./prep.sh master-node  (or worker-node-1, worker-node-2)
#
# What this does (for newcomers):
# 1. Disable swap - kubelet needs swap off
# 2. Load kernel modules - overlay + br_netfilter for container networking
# 3. Sysctl - enable bridge netfilter + IP forwarding for pods
# 4. Install containerd - the container runtime Kubernetes uses
# 5. Install kubeadm, kubelet, kubectl + conntrack - K8s tools
# 6. Set hostname (optional) - e.g. master-node, worker-node-1

HOSTNAME="${1:-}"

# --- Step 1: Disable swap ---
# Kubernetes expects swap disabled. Turn it off now and comment it out in /etc/fstab.
echo "=== Step 1: Disable swap ==="
sudo swapoff -a
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab

# --- Step 2: Load kernel modules ---
# overlay = container image layers; br_netfilter = bridge + iptables for pod networking
echo "=== Step 2: Load kernel modules ==="
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay && sudo modprobe br_netfilter

# --- Step 3: Sysctl (kernel networking) ---
# Bridge traffic through iptables + enable IP forwarding so pods can talk to each other
echo "=== Step 3: Sysctl ==="
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# --- Step 4: Install containerd ---
# containerd is the container runtime (runs containers). Kubernetes uses CRI to talk to it.
# We use Ubuntu's containerd package, not Docker's containerd.io.
echo "=== Step 4: Install containerd (Ubuntu package) ==="
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
# Kubernetes expects systemd cgroups; Ubuntu default is false, so we flip it
sudo sed -i 's/SystemdCgroup *= *false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# --- Step 5: Install Kubernetes tools ---
# kubeadm = bootstrap cluster; kubelet = runs pods; kubectl = CLI
# conntrack = required by kubeadm preflight; apt-transport-https + gpg = for K8s repo
echo "=== Step 5: Install conntrack and kubeadm, kubelet, kubectl ==="
sudo apt-get install -y conntrack apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl   # prevent auto-upgrades breaking the cluster

# --- Step 6: Set hostname (optional) ---
# Gives each node a clear name: master-node, worker-node-1, worker-node-2
if [ -n "$HOSTNAME" ]; then
  echo "=== Step 6: Set hostname to $HOSTNAME ==="
  sudo hostnamectl set-hostname "$HOSTNAME"
  echo "$HOSTNAME" | sudo tee /etc/hostname
  grep -q "$HOSTNAME" /etc/hosts || echo "127.0.1.1 $HOSTNAME" | sudo tee -a /etc/hosts
fi

echo "=== Prep complete ==="
