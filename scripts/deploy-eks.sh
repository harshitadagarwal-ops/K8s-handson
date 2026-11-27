#!/usr/bin/env bash
# Deploy the app to the EKS cluster created by Terraform.
#  1. point kubectl at the cluster
#  2. create the namespace, then app-config (RDS host) and app-secret (RDS
#     credentials read from AWS Secrets Manager; piped via stdin, never written
#     to disk, never in git)
#  3. render k8s/overlays/eks with the real ECR image names and apply it
# Needs: aws, kubectl, terraform, python3 (or python).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT/terraform/envs/dev"
tf_out() { terraform -chdir="$TF_DIR" output -raw "$1"; }

REGION="$(tf_out region)"
CLUSTER="$(tf_out cluster_name)"
BACKEND_REPO="$(tf_out ecr_backend_repo)"
FRONTEND_REPO="$(tf_out ecr_frontend_repo)"
DB_HOST="$(tf_out rds_address)"
DB_NAME="$(tf_out rds_db_name)"
SECRET_ARN="$(tf_out rds_secret_arn)"
TAG="${IMAGE_TAG:-$(cat "$ROOT/.image-tag")}"
PY="$(command -v python3 || command -v python)"

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER"

kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -

SECRET_JSON="$(aws secretsmanager get-secret-value --region "$REGION" --secret-id "$SECRET_ARN" --query SecretString --output text)"
SECRET_JSON="$SECRET_JSON" DB_HOST="$DB_HOST" DB_NAME="$DB_NAME" "$PY" - <<'PYEOF' | kubectl apply -f -
import json, os

cred = json.loads(os.environ["SECRET_JSON"])
print(json.dumps({
    "apiVersion": "v1",
    "kind": "List",
    "items": [
        {"apiVersion": "v1", "kind": "ConfigMap",
         "metadata": {"name": "app-config", "namespace": "demo"},
         "data": {"DB_HOST": os.environ["DB_HOST"], "DB_NAME": os.environ["DB_NAME"]}},
        {"apiVersion": "v1", "kind": "Secret", "type": "Opaque",
         "metadata": {"name": "app-secret", "namespace": "demo"},
         "stringData": {"DB_USER": cred["username"], "DB_PASSWORD": cred["password"]}},
    ],
}))
PYEOF

echo "Deploying image tag: $TAG"
kubectl kustomize "$ROOT/k8s/overlays/eks" \
  | sed -e "s|ECR_BACKEND_REPO|$BACKEND_REPO|g" \
        -e "s|ECR_FRONTEND_REPO|$FRONTEND_REPO|g" \
        -e "s|IMAGE_TAG|$TAG|g" \
  | kubectl apply -f -

kubectl -n demo rollout status deploy/backend --timeout=300s
kubectl -n demo rollout status deploy/frontend --timeout=300s

echo "Waiting for the load balancer hostname (can take 2-3 minutes)..."
for _ in $(seq 1 30); do
  LB="$(kubectl -n demo get svc frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [ -n "$LB" ]; then
    echo "App URL: http://$LB   (DNS may need another minute to resolve)"
    exit 0
  fi
  sleep 10
done
echo "Load balancer not ready yet. Check: kubectl -n demo get svc frontend"
