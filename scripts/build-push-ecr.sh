#!/usr/bin/env bash
# Build the backend and frontend images and push them to ECR.
# Reads repository URLs from `terraform output`, so run `terraform apply` first.
#
#   IMAGE_TAG=v1 ./scripts/build-push-ecr.sh     # optional fixed tag
#
# ECR tags are immutable: every build needs a new tag. The default is the git
# short SHA (plus a timestamp if the working tree is dirty). The tag is saved in
# .image-tag so scripts/deploy-eks.sh deploys exactly what was pushed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT/terraform/envs/dev"
tf_out() { terraform -chdir="$TF_DIR" output -raw "$1"; }

REGION="$(tf_out region)"
REGISTRY="$(tf_out ecr_registry)"
BACKEND_REPO="$(tf_out ecr_backend_repo)"
FRONTEND_REPO="$(tf_out ecr_frontend_repo)"

if [ -n "${IMAGE_TAG:-}" ]; then
  TAG="$IMAGE_TAG"
else
  TAG="$(git -C "$ROOT" rev-parse --short HEAD)"
  if [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
    TAG="$TAG-$(date +%Y%m%d%H%M%S)"
  fi
fi

echo "Logging in to $REGISTRY"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo "Building and pushing tag: $TAG"
docker build --platform linux/amd64 -t "$BACKEND_REPO:$TAG" "$ROOT/app/backend"
docker build --platform linux/amd64 -t "$FRONTEND_REPO:$TAG" "$ROOT/app/frontend"
docker push "$BACKEND_REPO:$TAG"
docker push "$FRONTEND_REPO:$TAG"

printf '%s' "$TAG" > "$ROOT/.image-tag"
echo "Done. Next: ./scripts/deploy-eks.sh"
