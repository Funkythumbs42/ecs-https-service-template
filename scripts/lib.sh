#!/usr/bin/env bash
# Shared helpers for the pipeline scripts. Source this file; don't execute directly.
set -euo pipefail

SERVICE_NAME="${SERVICE_NAME:-my-service}"
AWS_REGION="${AWS_REGION:-eu-west-1}"
export AWS_REGION AWS_DEFAULT_REGION="${AWS_REGION}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-${REPO_ROOT}/.artifacts}"
mkdir -p "${ARTIFACTS_DIR}"

log() { echo "==> $*" >&2; }
die() { echo "ERROR: $*" >&2; exit 1; }

require_env() {
  case "${1:-}" in
    dev | stage | prod) ;;
    *) die "environment must be one of dev|stage|prod (got '${1:-}')" ;;
  esac
}

# Fail unless running from the main branch (when the CI tells us the branch).
require_main_branch() {
  local b="${GIT_BRANCH:-}"
  b="${b#refs/heads/}"
  if [[ -n "$b" && "$b" != "main" && "$b" != "<default>" ]]; then
    die "this step may only run from main (current branch: $b)"
  fi
}

# AWS auth: no static keys. The agent's ambient identity (instance profile,
# ECS task role, or a TeamCity AWS connection) is used to assume the deploy role.
aws_auth() {
  if [[ -z "${AWS_ROLE_ARN:-}" ]]; then
    log "AWS_ROLE_ARN not set; using the agent's ambient AWS identity"
    return 0
  fi
  if [[ "${_AWS_ROLE_ASSUMED:-}" == "${AWS_ROLE_ARN}" ]]; then return 0; fi
  log "Assuming role ${AWS_ROLE_ARN}"
  local creds
  creds="$(aws sts assume-role \
    --role-arn "${AWS_ROLE_ARN}" \
    --role-session-name "ci-${SERVICE_NAME}-$(date +%s)" \
    --duration-seconds 3600 \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)"
  read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<<"${creds}"
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  export _AWS_ROLE_ASSUMED="${AWS_ROLE_ARN}"
}

ssm_prefix() { echo "/services/${SERVICE_NAME}/$1"; }

# ssm_get <env> <name>  -> prints value, or empty string if missing
ssm_get() {
  aws ssm get-parameter --name "$(ssm_prefix "$1")/$2" \
    --query 'Parameter.Value' --output text 2>/dev/null || true
}

# ssm_put <env> <name> <value>
ssm_put() {
  aws ssm put-parameter --name "$(ssm_prefix "$1")/$2" \
    --type String --overwrite --value "$3" >/dev/null
}

git_sha() {
  echo "${BUILD_VCS_NUMBER:-$(git -C "${REPO_ROOT}" rev-parse HEAD)}" | cut -c1-12
}
