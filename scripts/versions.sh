#!/usr/bin/env bash
#
# Prints the "Versions" section of the release notes in Markdown: for each
# image the tools it contains (from scripts/*-tools.env and the Dockerfiles) and
# its base image. Used by the Release Check workflow.

set -euo pipefail

cd "$(dirname "$0")/.."

# base prints the image the last stage of a Dockerfile is built from.
base() { sed -n 's/^FROM \([^ ]*\).*/\1/p' "$1" | tail -n1; }

row() { printf '| %s | %s |\n' "$1" "$2"; }

section() {
  printf '\n### %s\n\n| Component | Version |\n| --- | --- |\n' "$1"
}

printf '## Versions\n'

section 'security-scanner'
(
  . scripts/security-tools.env
  row govulncheck "$GOVULNCHECK_VERSION"
  row gosec "$GOSEC_VERSION"
  row gitleaks "$GITLEAKS_VERSION"
  row 'Base image' "\`$(base docker/security/Dockerfile)\`"
)

section 'go-test-runner'
(
  . scripts/go-test-runner-tools.env
  row Playwright "$PLAYWRIGHT_VERSION"
  row Node.js "$NODE_VERSION"
  row gocover-cobertura "$GOCOVER_COBERTURA_VERSION"
  row gotestfmt "$GOTESTFMT_VERSION"
  row 'Base image' "\`$(base docker/go-test-runner/Dockerfile)\`"
)

section 'wails3-builder'
(
  . scripts/wails3-builder-tools.env
  linuxdeploy=$(sed -n 's/^ARG LINUXDEPLOY_VERSION=//p' docker/wails3-builder/Dockerfile)
  row Go "$GO_VERSION"
  row wails3 "$WAILS_VERSION"
  row garble "$GARBLE_VERSION"
  row linuxdeploy "$linuxdeploy"
  row 'Base image' "\`$(base docker/wails3-builder/Dockerfile)\`"
)
