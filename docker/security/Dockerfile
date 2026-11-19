# Security scanner image: Go plus govulncheck, gosec and gitleaks, installed once
# instead of compiled on every run. The versions come from
# scripts/security-tools.env. Build with scripts/build.sh.

FROM golang:1.27

ARG GOVULNCHECK_VERSION
ARG GOSEC_VERSION
ARG GITLEAKS_VERSION

# The tool versions, readable without pulling the image.
LABEL tools.govulncheck.version=$GOVULNCHECK_VERSION \
      tools.gosec.version=$GOSEC_VERSION \
      tools.gitleaks.version=$GITLEAKS_VERSION

# GOBIN keeps the binaries out of GOPATH, which the workflow's module cache may
# shadow. GOTOOLCHAIN=auto lets go.mod ask for a newer Go than the image has.
ENV GOBIN=/usr/local/bin \
    GOTOOLCHAIN=auto

RUN apt-get install -y --no-install-recommends build-essential pkg-config libgtk-4-dev libwebkitgtk-6.0-dev libssl-dev

RUN test -n "$GOVULNCHECK_VERSION" && test -n "$GOSEC_VERSION" && test -n "$GITLEAKS_VERSION" \
 && go install golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION} \
 && go install github.com/securego/gosec/v2/cmd/gosec@${GOSEC_VERSION} \
 && go install github.com/zricethezav/gitleaks/v8@${GITLEAKS_VERSION} \
 && go clean -cache -modcache
