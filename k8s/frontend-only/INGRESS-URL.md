# Frontend & Backend Ingress – working URLs

**Ingress is up for both frontend and backend.** Use either option below.

## Option 1: Browser / apps (recommended)

1. Add both hosts to your hosts file (run once):
   ```bash
   echo "192.168.64.3 frontend.fullstack-app.local backend.fullstack-app.local" | sudo tee -a /etc/hosts
   ```
   Or add separately:
   ```bash
   echo "192.168.64.3 frontend.fullstack-app.local" | sudo tee -a /etc/hosts
   echo "192.168.64.3 backend.fullstack-app.local" | sudo tee -a /etc/hosts
   ```
2. Open in browser:
   - **Frontend:** http://frontend.fullstack-app.local:30814
   - **Backend:** http://backend.fullstack-app.local:30814
   - **Backend API (e.g. todos):** http://backend.fullstack-app.local:30814/todos

## Option 2: curl with Host header

```bash
curl -H "Host: frontend.fullstack-app.local" http://192.168.64.3:30814/
curl -H "Host: backend.fullstack-app.local" http://192.168.64.3:30814/
curl -H "Host: backend.fullstack-app.local" http://192.168.64.3:30814/todos
```

---

**Note:** Port `30814` is the NodePort for the ingress-nginx controller. If you reinstall the controller, the port may change; run `kubectl get svc -n ingress-nginx ingress-nginx-controller` to see the current port.

**Frontend calling backend:** The API URL is baked into the frontend at **build time** (Vite). Rebuild with:
`docker build --build-arg VITE_API_URL=http://backend.fullstack-app.local:30814 -t mogobanyamwaro/react-frontend:latest -f frontend/Dockerfile frontend/`
Then either push that image and restart the deployment, or load it into the cluster (see below). The deployment env var `VITE_API_URL` does not change the bundle.

### Using your built frontend image in the cluster

The deployment uses `mogobanyamwaro/react-frontend:latest`. So either:

**A) Push and pull (if you use Docker Hub)**

```bash
docker build --build-arg VITE_API_URL=http://backend.fullstack-app.local:30814 -t mogobanyamwaro/react-frontend:latest -f frontend/Dockerfile frontend/
docker push mogobanyamwaro/react-frontend:latest
kubectl rollout restart deployment/frontend -n fullstack-app
```

**B) Load local image into MicroK8s (no push)**

```bash
# Build and tag to match the deployment image name
docker build --build-arg VITE_API_URL=http://backend.fullstack-app.local:30814 -t mogobanyamwaro/react-frontend:latest -f frontend/Dockerfile frontend/
docker save mogobanyamwaro/react-frontend:latest | microk8s ctr image import -
kubectl rollout restart deployment/frontend -n fullstack-app
```

With `imagePullPolicy: IfNotPresent`, the cluster will use the image you imported.
