#!/bin/bash
set -e

# Tag and push backend + frontend to Docker Hub for dev, staging, or prod.
# Uses local images: mogobanyamwaro/nest-backend, mogobanyamwaro/react-frontend (see docker images).
# If backend has no :latest tag, the script tags the existing backend image as :latest and uses it.
# Override with BACKEND_IMAGE / FRONTEND_IMAGE / SRC_TAG env vars if needed.

BACKEND_IMAGE="${BACKEND_IMAGE:-mogobanyamwaro/nest-backend}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-mogobanyamwaro/react-frontend}"
SRC_TAG="${SRC_TAG:-latest}"

# If backend has no SRC_TAG but an image with this repo exists (e.g. tag <none>), tag it so we can push
ensure_backend_tagged() {
  if docker image inspect "${BACKEND_IMAGE}:${SRC_TAG}" &>/dev/null; then
    return 0
  fi
  local id
  id=$(docker images "${BACKEND_IMAGE}" --format "{{.ID}}" | head -1)
  if [[ -n "$id" ]]; then
    echo "Backend image has no :${SRC_TAG} tag; tagging ${BACKEND_IMAGE} (${id}) as :${SRC_TAG}"
    docker tag "${id}" "${BACKEND_IMAGE}:${SRC_TAG}"
  fi
}

# If frontend has no SRC_TAG but an image with this repo exists, tag the most recent one
ensure_frontend_tagged() {
  if docker image inspect "${FRONTEND_IMAGE}:${SRC_TAG}" &>/dev/null; then
    return 0
  fi
  local id
  id=$(docker images "${FRONTEND_IMAGE}" --format "{{.ID}}" | head -1)
  if [[ -n "$id" ]]; then
    echo "Frontend image has no :${SRC_TAG} tag; tagging ${FRONTEND_IMAGE} (${id}) as :${SRC_TAG}"
    docker tag "${id}" "${FRONTEND_IMAGE}:${SRC_TAG}"
  fi
}

check_images() {
  ensure_backend_tagged
  ensure_frontend_tagged
  local missing=""
  docker image inspect "${BACKEND_IMAGE}:${SRC_TAG}" &>/dev/null  || missing="${missing}  - ${BACKEND_IMAGE}:${SRC_TAG}\n"
  docker image inspect "${FRONTEND_IMAGE}:${SRC_TAG}" &>/dev/null || missing="${missing}  - ${FRONTEND_IMAGE}:${SRC_TAG}\n"
  if [[ -n "$missing" ]]; then
    echo "Missing local image(s). Build them first or set BACKEND_IMAGE / FRONTEND_IMAGE / SRC_TAG:"
    echo -e "$missing"
    echo "Build from repo root:"
    echo "  docker build -t ${BACKEND_IMAGE}:${SRC_TAG} ./backend"
    echo "  docker build -t ${FRONTEND_IMAGE}:${SRC_TAG} ./frontend"
    echo ""
    echo "To see your images: docker images | grep -E 'nest-backend|react-frontend'"
    return 1
  fi
  echo "Using backend:  ${BACKEND_IMAGE}:${SRC_TAG}"
  echo "Using frontend: ${FRONTEND_IMAGE}:${SRC_TAG}"
  return 0
}

tag_and_push() {
  local env=$1
  case $env in
    dev)     local tag=dev-latest ;;
    staging) local tag=staging-latest ;;
    prod)    local tag=1.0.0 ;;
    *)       echo "Unknown env: $env"; return 1 ;;
  esac

  echo "📦 Tagging and pushing for $env (tag: $tag)..."
  docker tag "${BACKEND_IMAGE}:${SRC_TAG}"  "${BACKEND_IMAGE}:${tag}"
  docker tag "${FRONTEND_IMAGE}:${SRC_TAG}" "${FRONTEND_IMAGE}:${tag}"
  docker push "${BACKEND_IMAGE}:${tag}"
  docker push "${FRONTEND_IMAGE}:${tag}"
  echo "✅ $env done."
}

ENV=${1:-}

case $ENV in
  dev|staging|prod)
    check_images "$ENV" || exit 1
    tag_and_push "$ENV"
    ;;
  all)
    check_images "dev" || exit 1
    tag_and_push dev
    tag_and_push staging
    tag_and_push prod
    ;;
  *)
    echo "Usage: ./push-images.sh [dev|staging|prod|all]"
    echo ""
    echo "  Tags and pushes backend + frontend to Docker Hub."
    echo "  Local images must exist as ${BACKEND_IMAGE}:${SRC_TAG} and ${FRONTEND_IMAGE}:${SRC_TAG}."
    echo ""
    echo "  dev     -> dev-latest"
    echo "  staging -> staging-latest"
    echo "  prod    -> 1.0.0"
    echo "  all     -> all three environments"
    echo ""
    echo "  Optional: BACKEND_IMAGE=... FRONTEND_IMAGE=... SRC_TAG=... ./push-images.sh dev"
    exit 1
    ;;
esac
