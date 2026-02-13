# k8s-from-scratch — Build a 3-Node Kubernetes Cluster

**Read this first.** Everything you need is in this README.

Build a Kubernetes cluster from scratch using kubeadm. One control plane + two workers. Ubuntu 22.04/24.04.

**Context:** Fullstack app repo. Nodes from `../terraform` (AWS EC2). SSH key: `../terraform.pem`.

---

## What's in This Folder

| File | Purpose |
|------|---------|
| `prep.sh` | Run on each node. Prepares OS: swap off, kernel modules, containerd, kubeadm/kubelet/kubectl. |
| `init-master.sh` | Run on control plane only. Bootstraps cluster and installs Flannel. |
| `setup.sh` | One-shot automation: SSHs to all nodes and runs prep → init → join → verify. |
| `verify-cluster.sh` | Checks cluster: `kubectl get nodes` and `kubectl get pods -A`. |
| `reset-node.sh` | `kubeadm reset` on a node (e.g. former control plane) so it can rejoin as worker. |

---

## End-to-End Flow (5 Steps)

```
Step 0          Step 1           Step 2           Step 3           Step 4           Step 5
terraform       prep.sh          init-master.sh   (Flannel)        kubeadm join     verify
   │                │                  │               │                 │              │
   ▼                ▼                  ▼               ▼                 ▼              ▼
[3 EC2s]  →  [all 3 nodes]  →  [master only]  →  [automatic]  →  [each worker]  →  [kubectl get nodes]
```

---

## Prerequisites

- 3 Ubuntu nodes (1 control plane, 2 workers)
- Nodes can reach each other on private network; security group allows port **6443** (K8s API)
- SSH key and sudo/root on all nodes
- Unique hostnames (e.g. `master-node`, `worker-node-1`, `worker-node-2`)

---

## Step 0: Provision Nodes

From project root:

```bash
cd terraform
terraform init
terraform apply
terraform output   # note instance_public_ips
```

Update `setup.sh` and `verify-cluster.sh`: set CP, W1, W2 (and CP in verify-cluster) to the three public IPs (control plane first).

---

## Step 1: Prep All Nodes

**What:** Disable swap, load kernel modules, set sysctl, install containerd + kubeadm/kubelet/kubectl, set hostname.

**Manual:** SSH to each node and run:

```bash
./prep.sh master-node     # on control plane
./prep.sh worker-node-1   # on worker 1
./prep.sh worker-node-2   # on worker 2
```

**Automated:** `setup.sh` does this via SSH.

---

## Step 2: Init Cluster (Master Only)

**What:** `kubeadm init` creates certificates, starts API server/etcd/scheduler/controller-manager, and prints a join command.

**Run on master:**

```bash
./init-master.sh
```

Save the `kubeadm join ...` line from the output.

---

## Step 3: Pod Network (Flannel)

**What:** Pods need a CNI to talk to each other. Flannel is applied automatically by `init-master.sh`.

If you init manually, run:

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

---

## Step 4: Join Workers

On each worker, run the join command from Step 2:

```bash
sudo kubeadm join <MASTER_PRIVATE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

Master private IP is typically shown in the join command (e.g. `10.0.x.x`). Workers must reach the master on port 6443 (VPC security group).

---

## Step 5: Verify

On master:

```bash
kubectl get nodes
kubectl get pods -A
```

Or from laptop:

```bash
./verify-cluster.sh
```

All 3 nodes should be `Ready`. CoreDNS, kube-proxy, and Flannel pods should be `Running`.

---

## Quick Reference

| Step | Where | Action |
|------|-------|--------|
| 0 | Laptop | `terraform apply`; update IPs in setup.sh, verify-cluster.sh |
| 1 | All 3 nodes | `./prep.sh master-node` (or worker-node-1/2) |
| 2 | Master | `./init-master.sh`; copy join command |
| 3 | Master | Done by init-master.sh |
| 4 | Each worker | `sudo kubeadm join ...` |
| 5 | Master or laptop | `kubectl get nodes` or `./verify-cluster.sh` |

---

## Automated Setup

After `terraform apply`, edit the IPs at the top of `setup.sh`, then:

```bash
./setup.sh
```

This runs prep, init, join, and verify for you.

---

## Manual vs Automated

- **Manual:** Copy scripts to each node, run prep → init → join by hand. Good for learning.
- **Automated:** Run `setup.sh` from your laptop. Good for repeat builds.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `conntrack not found` | Install conntrack: `sudo apt install -y conntrack`. prep.sh includes this. |
| Worker stuck at preflight | Ensure port 6443 is open between nodes (security group: allow VPC CIDR). |
| Worker was previously control plane | Run `./reset-node.sh <worker-ip>` then prep and join again. |
| Token expired | On master: `sudo kubeadm token create --print-join-command` |
| Need to run kubectl from laptop | SSH to master: `ssh -i terraform.pem ubuntu@<CP> "kubectl get nodes"` or use `verify-cluster.sh` |

---

## Tech Stack

- **Container runtime:** containerd (Ubuntu package)
- **Kubernetes:** kubeadm, kubelet, kubectl (v1.31 from pkgs.k8s.io)
- **CNI:** Flannel
- **OS:** Ubuntu 22.04
