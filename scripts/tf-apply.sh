#!/usr/bin/env bash
# terraform apply of a saved plan (from tf-plan.sh) for one environment.
#   usage: tf-apply.sh <env>
# Refuses to apply if an app deploy changed the image since the plan was made,
# so an infra apply can never roll the image back.
source "$(dirname "$0")/lib.sh"
ENV="${1:-}"; require_env "${ENV}"
require_main_branch
aws_auth
cd "${REPO_ROOT}/infra"

[[ -f "tfplan-${ENV}" ]] || die "plan file infra/tfplan-${ENV} not found; run tf-plan.sh ${ENV} first"
PLANNED="$(cat "${ARTIFACTS_DIR}/plan-digest-${ENV}.txt" 2>/dev/null || true)"
CURRENT="$(ssm_get "${ENV}" image-digest)"
[[ "${PLANNED}" == "${CURRENT}" ]] ||
  die "image digest changed since plan (${PLANNED:-none} -> ${CURRENT:-none}); re-run the plan"

terraform init -input=false -reconfigure -backend-config="envs/${ENV}.backend.hcl"
terraform apply -input=false "tfplan-${ENV}"
