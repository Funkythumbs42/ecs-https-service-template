#!/usr/bin/env bash
# Push the locally built image to ECR and record its digest.
#   usage: push.sh [tag]
# Output: .artifacts/image-digest.txt (sha256:...)
source "$(dirname "$0")/lib.sh"
aws_auth
TAG="${1:-$(cat "${ARTIFACTS_DIR}/image-tag.txt" 2>/dev/null || git_sha)}"

# The ECR repo URL is published by the dev infra stack.
REPO_URL="$(ssm_get dev ecr-repository-url)"
[[ -n "${REPO_URL}" ]] || die "ECR URL not found in SSM; apply the dev infra first"
REGISTRY="${REPO_URL%%/*}"

aws ecr get-login-password | docker login --username AWS --password-stdin "${REGISTRY}"

digest_for_tag() {
  aws ecr describe-images --repository-name "${SERVICE_NAME}" \
    --image-ids imageTag="$1" --query 'imageDetails[0].imageDigest' --output text 2>/dev/null || true
}

DIGEST="$(digest_for_tag "${TAG}")"
if [[ -n "${DIGEST}" && "${DIGEST}" != "None" ]]; then
  log "Tag ${TAG} already in ECR (tags are immutable); reusing ${DIGEST}"
else
  docker tag "${SERVICE_NAME}:${TAG}" "${REPO_URL}:${TAG}"
  docker push "${REPO_URL}:${TAG}"
  DIGEST="$(digest_for_tag "${TAG}")"
fi

[[ "${DIGEST}" =~ ^sha256:[a-f0-9]{64}$ ]] || die "could not resolve digest for ${TAG}"
echo "${DIGEST}" >"${ARTIFACTS_DIR}/image-digest.txt"
log "Pushed ${REPO_URL}@${DIGEST}"
