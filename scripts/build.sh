#!/usr/bin/env bash
# Build the linux/arm64 image with buildx and load the result into the local docker store.
# Works on x86_64 agents too: the Dockerfile cross-compiles from $BUILDPLATFORM.
#   usage: build.sh [tag]
source "$(dirname "$0")/lib.sh"
TAG="${1:-$(git_sha)}"
PLATFORM="${PLATFORM:-linux/arm64}"

docker buildx inspect >/dev/null 2>&1 || docker buildx create --use >/dev/null
log "Building ${SERVICE_NAME}:${TAG} for ${PLATFORM}"
docker buildx build \
  --platform "${PLATFORM}" \
  --provenance=false \
  --load \
  -t "${SERVICE_NAME}:${TAG}" \
  "${REPO_ROOT}/app"
echo "${TAG}" >"${ARTIFACTS_DIR}/image-tag.txt"
