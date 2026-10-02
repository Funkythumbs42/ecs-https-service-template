#!/usr/bin/env bash
# Deploy an image digest to an environment's ECS service.
#   usage: deploy.sh <env> [digest]   (digest defaults to .artifacts/image-digest.txt)
#
# Takes the service's current task definition (owned by Terraform), swaps only
# the image, registers a new revision, rolls the service and waits. The ECS
# deployment circuit breaker rolls back automatically on failure; we detect that
# and fail the step. On success the digest is recorded in SSM
# (/services/<service>/<env>/image-digest) so Terraform keeps using that digest.
source "$(dirname "$0")/lib.sh"
ENV="${1:-}"; require_env "${ENV}"
DIGEST="${2:-$(cat "${ARTIFACTS_DIR}/image-digest.txt" 2>/dev/null || true)}"
[[ "${DIGEST}" =~ ^sha256:[a-f0-9]{64}$ ]] || die "invalid or missing digest '${DIGEST}'"
aws_auth

CLUSTER="$(ssm_get "${ENV}" cluster-name)"
SERVICE="$(ssm_get "${ENV}" service-name)"
CONTAINER="$(ssm_get "${ENV}" container-name)"
REPO_URL="$(ssm_get "${ENV}" ecr-repository-url)"
[[ -n "${CLUSTER}" && -n "${SERVICE}" ]] || die "service metadata missing in SSM; apply ${ENV} infra first"
IMAGE="${REPO_URL}@${DIGEST}"

CURRENT_TD="$(aws ecs describe-services --cluster "${CLUSTER}" --services "${SERVICE}" \
  --query 'services[0].taskDefinition' --output text)"
log "Current task definition: ${CURRENT_TD}"

NEW_TD_JSON="$(aws ecs describe-task-definition --task-definition "${CURRENT_TD}" --query taskDefinition |
  jq --arg c "${CONTAINER}" --arg img "${IMAGE}" '
    .containerDefinitions |= map(if .name == $c then .image = $img else . end)
    | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities,
          .registeredAt, .registeredBy, .deregisteredAt)')"

NEW_TD="$(aws ecs register-task-definition --cli-input-json "${NEW_TD_JSON}" \
  --query 'taskDefinition.taskDefinitionArn' --output text)"
log "Registered ${NEW_TD} with image ${IMAGE}"

# First deploy after bootstrap: Terraform created the service with 0 tasks.
DESIRED="$(aws ecs describe-services --cluster "${CLUSTER}" --services "${SERVICE}" \
  --query 'services[0].desiredCount' --output text)"
COUNT_ARGS=()
if [[ "${DESIRED}" == "0" ]]; then COUNT_ARGS=(--desired-count "${BOOTSTRAP_DESIRED_COUNT:-1}"); fi

aws ecs update-service --cluster "${CLUSTER}" --service "${SERVICE}" \
  --task-definition "${NEW_TD}" "${COUNT_ARGS[@]}" >/dev/null

log "Waiting for ${SERVICE} to become stable..."
aws ecs wait services-stable --cluster "${CLUSTER}" --services "${SERVICE}"

# services-stable also succeeds after a circuit-breaker rollback, so check
# that the PRIMARY deployment is really ours and completed.
# shellcheck disable=SC2016 # JMESPath backticks, not shell
read -r PRIMARY_TD ROLLOUT <<<"$(aws ecs describe-services --cluster "${CLUSTER}" --services "${SERVICE}" \
  --query 'services[0].deployments[?status==`PRIMARY`] | [0].[taskDefinition,rolloutState]' --output text)"
[[ "${PRIMARY_TD}" == "${NEW_TD}" && "${ROLLOUT}" == "COMPLETED" ]] ||
  die "deployment did not complete (primary=${PRIMARY_TD} state=${ROLLOUT}); circuit breaker rolled back"

ssm_put "${ENV}" image-digest "${DIGEST}"
log "Deployed ${DIGEST} to ${ENV}"
