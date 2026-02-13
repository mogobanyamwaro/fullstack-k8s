# Kubernetes: base + overlays (dev, staging, prod)

## Layout

- **base/** – Shared resources: Postgres, backend (Nest, port 4000), frontend (Vite, port 3000), ingress. All use namespace `fullstack-app` (overlays override).
- **overlays/dev** – Development: namespace `fullstack-dev`, 1 replica, lower resources. Hosts: `frontend.dev.fullstack-app.local`, `backend.dev.fullstack-app.local`.
- **overlays/staging** – Staging: namespace `fullstack-staging`, HPA, hosts: `frontend.staging.fullstack-app.local`, `backend.staging.fullstack-app.local`.
- **overlays/prod** – Production: namespace `fullstack-prod`, HPA, TLS (cert-manager). Hosts: `app.fullstack-app.com`, `api.fullstack-app.com`.

## Deploy

From the `k8s` directory:

```bash
./deploy.sh dev      # fullstack-dev
./deploy.sh staging  # fullstack-staging
./deploy.sh prod     # fullstack-prod
```

Or from repo root: `./k8s/deploy.sh dev`

**Delete** an environment: `./delete.sh [dev|staging|prod]`

## Docker images and tags

Each overlay expects specific image tags on Docker Hub. You must push these before (or after) deploying:

| Environment | Backend | Frontend |
|-------------|---------|----------|
| **dev** | `mogobanyamwaro/nest-backend:dev-latest` | `mogobanyamwaro/react-frontend:dev-latest` |
| **staging** | `mogobanyamwaro/nest-backend:staging-latest` | `mogobanyamwaro/react-frontend:staging-latest` |
| **prod** | `mogobanyamwaro/nest-backend:1.0.0` | `mogobanyamwaro/react-frontend:1.0.0` |

**Script:** from `k8s/` run `./push-images.sh [dev|staging|prod|all]` to tag (from `:latest`) and push both images. Requires local images `mogobanyamwaro/nest-backend:latest` and `mogobanyamwaro/react-frontend:latest`.

Or manually, e.g. for dev:

```bash
docker tag mogobanyamwaro/nest-backend:latest   mogobanyamwaro/nest-backend:dev-latest
docker tag mogobanyamwaro/react-frontend:latest mogobanyamwaro/react-frontend:dev-latest
docker push mogobanyamwaro/nest-backend:dev-latest
docker push mogobanyamwaro/react-frontend:dev-latest
```

Build the frontend with the correct `VITE_API_URL` for each env before building/pushing.

## Frontend API URL (Vite)

`VITE_API_URL` is set per overlay (configmap). It is **baked into the frontend at build time**, so build the image with the same URL you use in that env, e.g.:

- Dev: `docker build --build-arg VITE_API_URL=http://backend.dev.fullstack-app.local -t ...`
- Prod: `docker build --build-arg VITE_API_URL=https://api.fullstack-app.com -t ...`

## Optional: single-stack deploys

- **postgres-only/** – Postgres only.
- **backend-only/** – Postgres + backend.
- **frontend-only/** – Postgres + backend + frontend (full stack in one namespace).

Apply with: `kubectl apply -k k8s/postgres-only` (etc.).
