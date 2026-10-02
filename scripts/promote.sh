#!/usr/bin/env bash
# Promote the digest that passed the previous environment.
#   usage: promote.sh <stage|prod>
#   stage <- dev's smoke-passed-digest, prod <- stage's smoke-passed-digest
# Override the source digest explicitly with DIGEST=sha256:... (the digest must still
# have passed dev).
source "$(dirname "$0")/lib.sh"
TARGET="${1:-}"
case "${TARGET}" in
  stage) SOURCE=dev ;;
  prod) SOURCE=stage ;;
  *) die "usage: promote.sh <stage|prod>" ;;
esac
require_main_branch
aws_auth

DIGEST="${DIGEST:-$(ssm_get "${SOURCE}" smoke-passed-digest)}"
[[ "${DIGEST}" =~ ^sha256:[a-f0-9]{64}$ ]] || die "no smoke-passed digest found for ${SOURCE}"

# Guard: only digests that have passed dev may ever be promoted.
DEV_PASSED_HISTORY="$(aws ssm get-parameter-history --name "$(ssm_prefix dev)/smoke-passed-digest" \
  --query 'Parameters[].Value' --output text)"
grep -qw "${DIGEST}" <<<"${DEV_PASSED_HISTORY}" || die "${DIGEST} never passed dev; refusing to promote"

aws ecr describe-images --repository-name "${SERVICE_NAME}" --image-ids imageDigest="${DIGEST}" >/dev/null ||
  die "${DIGEST} not found in ECR (expired by lifecycle policy?)"

log "Promoting ${DIGEST}: ${SOURCE} -> ${TARGET}"
"$(dirname "$0")/deploy.sh" "${TARGET}" "${DIGEST}"
"$(dirname "$0")/smoke.sh" "${TARGET}"
