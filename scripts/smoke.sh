#!/usr/bin/env bash
# Smoke test an environment over its public HTTPS URL.
#   usage: smoke.sh <env>      (or: BASE_URL=http://localhost:8080 smoke.sh local)
# On success for a real env, records the deployed digest as
# /services/<service>/<env>/smoke-passed-digest - promote.sh only promotes those.
source "$(dirname "$0")/lib.sh"
ENV="${1:-}"
if [[ "${ENV}" != "local" ]]; then
  require_env "${ENV}"
  aws_auth
  BASE_URL="${BASE_URL:-$(ssm_get "${ENV}" url)}"
fi
[[ -n "${BASE_URL:-}" ]] || die "BASE_URL unknown"

log "Smoke testing ${BASE_URL}"
curl -fsS --retry 10 --retry-delay 6 --retry-all-errors --max-time 10 "${BASE_URL}/health" >/dev/null
curl -fsS --max-time 10 "${BASE_URL}/" | grep -qi hello || die "/ did not return hello"
log "Smoke test passed"

if [[ "${ENV}" != "local" ]]; then
  DIGEST="$(ssm_get "${ENV}" image-digest)"
  if [[ -n "${DIGEST}" ]]; then ssm_put "${ENV}" smoke-passed-digest "${DIGEST}"; fi
fi
