#!/usr/bin/env bash
# terraform plan for one environment.
#   usage: tf-plan.sh <env>
# The image digest is read from SSM (/services/<service>/<env>/image-digest),
# so an infra change always keeps the image that is currently deployed.
# Output: infra/tfplan-<env> and .artifacts/plan-digest-<env>.txt
source "$(dirname "$0")/lib.sh"
ENV="${1:-}"; require_env "${ENV}"
aws_auth
cd "${REPO_ROOT}/infra"

terraform fmt -check -recursive
terraform init -input=false -reconfigure -backend-config="envs/${ENV}.backend.hcl"
terraform validate

DIGEST="$(ssm_get "${ENV}" image-digest)"
log "Using image digest from SSM: ${DIGEST:-<none - bootstrap>}"
echo "${DIGEST}" >"${ARTIFACTS_DIR}/plan-digest-${ENV}.txt"

terraform plan -input=false \
  -var-file="envs/${ENV}.tfvars" \
  -var "image_digest=${DIGEST}" \
  -out="tfplan-${ENV}"
