#!/usr/bin/env bash
#
# Runs the checks of the Security workflow (.github/workflows/security.yml)
# locally: a Trivy misconfiguration scan and a Checkov scan of the Dockerfiles
# in docker/. Needs Docker. Exits non-zero if any check fails.

set -uo pipefail

cd "$(dirname "$0")/.."

TRIVY_IMAGE=aquasec/trivy:0.58.0
CHECKOV_IMAGE=bridgecrew/checkov:3

status=0

echo "==> trivy config"
docker run --rm -v "$PWD":/src -w /src "$TRIVY_IMAGE" \
  config --exit-code 1 --severity MEDIUM,HIGH,CRITICAL \
  --ignorefile .trivyignore docker || status=1

# CKV_DOCKER_2 (HEALTHCHECK) and CKV_DOCKER_3 (non-root USER) do not fit images
# that only run as short-lived CI job containers.
echo "==> checkov"
docker run --rm -v "$PWD":/src -w /src "$CHECKOV_IMAGE" \
  -d docker --framework dockerfile --compact \
  --skip-check CKV_DOCKER_2,CKV_DOCKER_3 || status=1

if [ "$status" -eq 0 ]; then
  echo "All checks passed"
else
  echo "Some checks failed" >&2
fi
exit "$status"
