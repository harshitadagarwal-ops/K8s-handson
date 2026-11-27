#!/usr/bin/env bash
# Tear everything down, in the right order.
# The Network Load Balancer is created by Kubernetes, not Terraform. If it is
# still alive, `terraform destroy` hangs on the VPC. So delete the namespace
# first (this removes the load balancer), then destroy the infrastructure.
#
#   ./scripts/destroy-eks.sh              # asks for confirmation
#   ./scripts/destroy-eks.sh -auto-approve
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT/terraform/envs/dev"

REGION="$(terraform -chdir="$TF_DIR" output -raw region)"
CLUSTER="$(terraform -chdir="$TF_DIR" output -raw cluster_name)"

if aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER" >/dev/null 2>&1 \
   && kubectl get ns demo >/dev/null 2>&1; then
  echo "Deleting namespace demo (removes the load balancer)..."
  kubectl delete ns demo --wait --timeout=10m
else
  echo "WARNING: could not reach the cluster. If a load balancer still exists, delete it in the EC2 console or the VPC destroy will hang." >&2
fi

terraform -chdir="$TF_DIR" destroy "$@"

