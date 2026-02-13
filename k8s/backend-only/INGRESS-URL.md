# Backend Ingress – working URL

**Ingress is up.** Use either option below.

## Option 1: Browser / apps (recommended)

1. Add the host to your hosts file (run once):
   ```bash
   echo "192.168.64.3 backend.fullstack-app.local" | sudo tee -a /etc/hosts
   ```
2. Open in browser or call from app:
   - **Base URL:** `http://backend.fullstack-app.local:30814`
   - **Examples:**
     - Root: http://backend.fullstack-app.local:30814/
     - Todos: http://backend.fullstack-app.local:30814/todos

## Option 2: curl with Host header

```bash
curl -H "Host: backend.fullstack-app.local" http://192.168.64.3:30814/
curl -H "Host: backend.fullstack-app.local" http://192.168.64.3:30814/todos
```

---

**Note:** Port `30814` is the NodePort for the ingress-nginx controller. If you reinstall the controller, the port may change; run `kubectl get svc -n ingress-nginx ingress-nginx-controller` to see the current port.
