#!/usr/bin/env bash
#
# Runs the checks of the Test workflow (.github/workflows/test.yml) locally:
# BuildKit's Dockerfile check and hadolint (errors and warnings fail) on every Dockerfile in docker/.
# Needs Docker. Exits non-zero if any check fails.

set -uo pipefail

cd "$(dirname "$0")/.."

HADOLINT_IMAGE=hadolint/hadolint:v2.12.0

status=0
for f in docker/*/Dockerfile*; do
  echo "==> docker build --check $f"
  docker build --check -f "$f" . || status=1

  echo "==> hadolint $f"
  docker run --rm -i "$HADOLINT_IMAGE" hadolint --failure-threshold warning - < "$f" || status=1
done

if [ "$status" -eq 0 ]; then
  echo "All checks passed"
else
  echo "Some checks failed" >&2
fi
exit "$status"
