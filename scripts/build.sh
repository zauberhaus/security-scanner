#!/usr/bin/env bash
#
# Build the security scanner image locally, and optionally push it to the
# GitHub Container Registry (ghcr.io).
#
#   scripts/build.sh                  build ghcr.io/OWNER/security-scanner:dev
#   scripts/build.sh -x               build the go-test-runner image
#   scripts/build.sh -t 1.2.3 -p      build and push :1.2.3
#
# Pushing needs `docker login ghcr.io` with a token that has write:packages.
set -euo pipefail

cd "$(dirname "$0")/.."

IMAGE=
TAG=dev
TESTIMG=false
PUSH=false
PLATFORMS=linux/amd64,linux/arm64

usage() {
  cat <<EOF2
Usage: $(basename "$0") [-i IMAGE] [-t TAG] [-P PLATFORMS] [-x] [-p] [-h]

  -i IMAGE  image name (default: ghcr.io/OWNER/security-scanner, OWNER from
            the origin remote)
  -t TAG    image tag (default: $TAG)
  -P LIST   comma separated platforms (default: $PLATFORMS)
  -x        build the go-test-runner image (docker/go-test-runner)
  -p        push the image after building it
  -h        show this help
EOF2
}

while getopts "i:t:P:xph" opt; do
  case "$opt" in
    i) IMAGE=$OPTARG ;;
    t) TAG=$OPTARG ;;
    P) PLATFORMS=$OPTARG ;;
    x) TESTIMG=true ;;
    p) PUSH=true ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

command -v docker >/dev/null || { echo "error: docker is required" >&2; exit 1; }

if [ -z "$IMAGE" ]; then
  owner=$(git remote get-url origin 2>/dev/null | sed -E 's#^(git@github.com:|https://github.com/)([^/]+)/.*#\2#' || true)
  [ -n "$owner" ] || { echo "error: cannot detect the owner; pass -i IMAGE" >&2; exit 1; }
  IMAGE=ghcr.io/$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')/security-scanner
fi

dockerfile=docker/security/Dockerfile
envfile=scripts/security-tools.env
if $TESTIMG; then
  dockerfile=docker/go-test-runner/Dockerfile
  envfile=scripts/go-test-runner-tools.env
  case $IMAGE in */security-scanner) IMAGE=${IMAGE%security-scanner}go-test-runner ;; esac
fi

build_args=()
while IFS='=' read -r key value; do
  case $key in
    ''|\#*) continue ;;
  esac
  build_args+=(--build-arg "$key=$value")
done < "$envfile"

echo "==> building $IMAGE:$TAG ($PLATFORMS)"
# A multi-platform image cannot be loaded into a classic Docker image store, so
# without -p it is only built (and kept in the build cache) unless the daemon
# uses the containerd image store, in which case it is loaded.
if $PUSH; then
  docker buildx build --platform "$PLATFORMS" -f "$dockerfile" "${build_args[@]}" -t "$IMAGE:$TAG" --push .
else
  docker buildx build --platform "$PLATFORMS" -f "$dockerfile" "${build_args[@]}" -t "$IMAGE:$TAG" --load .
fi
