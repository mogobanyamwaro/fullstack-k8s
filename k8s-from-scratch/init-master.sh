#!/bin/bash
set -e
# Run on CONTROL PLANE node only
#
# What this does (for newcomers):
# 1. kubeadm init - bootstraps the cluster (etcd, API server, scheduler, controller-manager)
# 2. Copy admin.conf - so kubectl works for your user
# 3. Install Flannel - pod network (CNI) so pods can talk to each other
# 4. Print join command - run that on each worker to add them to the cluster

MASTER_IP=$(hostname -I | awk '{print $1}')
echo "=== Initializing cluster at $MASTER_IP ==="

# Bootstrap the cluster. --pod-network-cidr must match Flannel's default (10.244.0.0/16)
sudo kubeadm init --apiserver-advertise-address="$MASTER_IP" --pod-network-cidr=10.244.0.0/16

# Make kubectl work for the ubuntu user (admin.conf has cluster admin credentials)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel CNI - gives each pod an IP and lets pods talk across nodes
echo "=== Installing Flannel ==="
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo ""
echo "=== Done. Run this on each worker node: ==="
sudo kubeadm token create --print-join-command
