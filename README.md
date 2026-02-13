# Fullstack App

Monorepo: backend (NestJS), frontend (React/Vite), Kubernetes manifests, Terraform infra, and cluster bootstrap.

## Structure

```
├── .github/workflows/    # CI/CD: backend, frontend, terraform
├── backend/              # NestJS API
├── frontend/             # React/Vite app
├── k8s/                  # K8s manifests (ArgoCD watches here)
│   ├── base/
│   └── overlays/dev|staging|prod
├── k8s-from-scratch/     # Cluster bootstrap (kubeadm)
├── terraform/            # AWS infra (VPC, EC2)
└── docker-compose.yml    # Local dev
```

## Quick Start

1. **Local dev:** `docker-compose up`
2. **Infra:** `cd terraform && terraform apply`
3. **Cluster:** See `k8s-from-scratch/README.md`
4. **Deploy:** `./k8s/deploy.sh dev` or use ArgoCD

## CI/CD (GitHub Actions + ArgoCD)

- **backend/** changes → build image → push to Docker Hub → update `k8s/overlays/dev`
- **frontend/** changes → same
- **terraform/** changes → `terraform plan`

Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

## ArgoCD

Point ArgoCD at this repo, path `k8s/overlays/dev` (or staging/prod). It syncs when manifests change.
