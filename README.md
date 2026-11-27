# K8s Microservices Demo

A 3-tier demo app for **Deploying Microservices on Kubernetes**. The same app runs in two places. Each has its own step-by-step guide:

| Target | Guide | Database | Exposed with | Use it for |
|--------|-------|----------|--------------|-----------|
| **Minikube** (local) | **[README-minikube.md](README-minikube.md)** | MySQL pod, `emptyDir` | NodePort | Learning, live demos without a cloud bill |
| **Amazon EKS** (Terraform) | **[README-eks.md](README-eks.md)** | Amazon RDS for MySQL | Network Load Balancer | A realistic cloud deployment |

```
Browser ──> frontend (Flask :8080) ──> backend (Flask REST API :5000) ──> MySQL
                                                                          (pod on Minikube, RDS on EKS)
```

- The frontend reaches the backend by Service name (`http://backend:5000`), which is cluster DNS service discovery.
- The backend reads `DB_HOST` and `DB_NAME` from a ConfigMap, and `DB_USER` and `DB_PASSWORD` from a Secret.

## Repository layout

```
.
├── app/
│   ├── backend/            Flask REST API + Dockerfile
│   └── frontend/           Flask web UI + Dockerfile
├── k8s/
│   ├── base/               namespace, backend, frontend (same everywhere)
│   └── overlays/
│       ├── minikube/       + MySQL pod, config/secret, NodePort
│       └── eks/            + ECR images, NLB (config/secret are created by the deploy script)
├── terraform/
│   ├── modules/            vpc, eks, ecr, rds
│   ├── envs/dev/           the stack you apply
│   └── bootstrap/          optional S3 bucket for remote Terraform state
├── scripts/                build-push-ecr, deploy-eks, destroy-eks (.sh and .ps1)
├── docs/diagrams/          slide diagrams
├── README.md               this overview
├── README-minikube.md      local demo guide
└── README-eks.md           AWS (Terraform + EKS + RDS) guide
```

Kustomize overlays keep one copy of the app manifests. Each overlay changes only what differs per environment (database, image source, how the frontend is exposed).

## Keeping the docs in sync

- A change that affects only one environment goes in that environment's README (for example a new Terraform variable goes in `README-eks.md`).
- A change to the shared app or `k8s/base` should be checked against both guides.
- Keep this file short: overview, layout, and links.
