# Run the demo on Minikube (local)

Back to the [project overview](README.md). To run on AWS instead, see [README-eks.md](README-eks.md).

```
Browser ──> frontend (Flask, NodePort) ──> backend (Flask REST API) ──> mysql (MySQL, emptyDir)
```

- **app/frontend/**: Flask web UI (port 8080), calls the backend by Service name.
- **app/backend/**: Flask REST API (port 5000), reads and writes MySQL.
- **k8s/base/**: namespace, backend, and frontend (shared with EKS).
- **k8s/overlays/minikube/**: MySQL pod, ConfigMap, Secret, and the NodePort for the frontend.

> MySQL uses `emptyDir` (temporary storage). Data is lost when the pod restarts. This is intentional for a beginner demo. Never do this in production.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (used as Minikube's driver)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

Verify:
```bash
docker version
minikube version
kubectl version --client
```

## Step-by-step demo

### 1. Start Minikube
```bash
minikube start
kubectl get nodes          # should show "minikube  Ready"
```

### 2. Build the images INSIDE Minikube
Minikube has its own Docker daemon. Point your shell at it so the images are available to the cluster without pushing to a registry.

**Linux / macOS:**
```bash
eval $(minikube docker-env)
```

**Windows PowerShell:**
```powershell
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
```

Then build (from the repo root):
```bash
docker build -t backend:latest ./app/backend
docker build -t frontend:latest ./app/frontend
```

### 3. Deploy everything
```bash
kubectl apply -k k8s/overlays/minikube
```
This applies the shared `k8s/base` plus the Minikube overlay (MySQL, config, secret, NodePort).

### 4. Watch it come up
```bash
kubectl get pods -n demo -w
# Wait until all pods are Running / READY 1/1  (MySQL takes ~30-60s the first time)
```

```bash
kubectl get svc -n demo
```

### 5. Open the app
```bash
minikube service frontend -n demo
```
This opens the frontend in your browser. Add a message; it's saved in MySQL via the backend.

## Live teaching moments

**Self-healing**: delete a pod and watch the Deployment recreate it:
```bash
kubectl get pods -n demo
kubectl delete pod <a-backend-pod-name> -n demo
kubectl get pods -n demo        # a new one is already being created
```

**Scaling**: change the number of replicas on the fly:
```bash
kubectl scale deployment backend --replicas=4 -n demo
kubectl get pods -n demo        # now 4 backend pods
```

**Inspecting**: useful for debugging:
```bash
kubectl describe deployment backend -n demo
kubectl logs deploy/backend -n demo
kubectl get all -n demo
```

**Dashboard (visual):**
```bash
minikube dashboard
```

## Cleanup
```bash
kubectl delete -k k8s/overlays/minikube     # remove the app
minikube stop                               # stop the cluster (keeps it)
minikube delete                             # delete the cluster entirely
```

## Troubleshooting

| Symptom | Check |
|---------|-------|
| `ErrImagePull` / `ImagePullBackOff` on backend or frontend | The images were built on your normal Docker, not Minikube's. Run the `docker-env` command from step 2 in the same terminal, then rebuild. |
| Backend log shows `DB not ready` | Normal for the first minute while MySQL starts. The backend retries on its own. |
| `minikube service` does not open a browser, or the URL stops working | With the Docker driver on Windows/macOS the command opens a tunnel. Keep that terminal open. |
| Messages disappear | The MySQL pod restarted. `emptyDir` storage is temporary by design. |

## Alternatives to Minikube

| Tool | What it is | Best for |
|------|-----------|----------|
| Minikube | Single-node local cluster | Learning / local dev (this demo) |
| kind | Kubernetes in Docker | CI, throwaway clusters |
| k3s | Lightweight Kubernetes | Edge / IoT / low-resource |
| Docker Desktop | Built-in K8s toggle | Docker Desktop users |
| EKS / GKE / AKS | Managed cloud Kubernetes | Production (see [README-eks.md](README-eks.md)) |
