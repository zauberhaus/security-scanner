# Test image: everything to build and test GUI examples like ui_shell/examples:
# Go with cgo, GTK and WebKit (Wails), Playwright with Chromium, Xvfb for a
# display, gocover-cobertura and gotestfmt. The versions come from
# scripts/go-test-runner-tools.env. Build with scripts/build.sh -x.

FROM golang:1.27

ARG GOCOVER_COBERTURA_VERSION
ARG GOTESTFMT_VERSION
ARG NODE_VERSION
ARG PLAYWRIGHT_VERSION

LABEL tools.gocover-cobertura.version=$GOCOVER_COBERTURA_VERSION \
      tools.gotestfmt.version=$GOTESTFMT_VERSION \
      tools.node.version=$NODE_VERSION \
      tools.playwright.version=$PLAYWRIGHT_VERSION

ENV GOBIN=/usr/local/bin \
    GOTOOLCHAIN=auto \
    CGO_ENABLED=1 \
    DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# GTK and WebKit for Wails: GTK 3 with WebKitGTK 4.1 and GTK 4 with WebKitGTK 6
# (the default of Wails v3 and its gtk3 build tag). Xvfb and dbus give GUI tests
# a display, e.g. `xvfb-run -a go test ./...`. Not pinned (DL3008): the base
# image is a moving tag and Debian drops old package versions, so a pin would
# break the build.
# hadolint ignore=DL3008
RUN apt-get -o Acquire::Retries=5 update \
 && apt-get -o Acquire::Retries=5 upgrade -y \
 && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
      build-essential pkg-config git curl ca-certificates xz-utils \
      libgtk-3-dev libwebkit2gtk-4.1-dev \
      libgtk-4-dev libwebkitgtk-6.0-dev \
      xvfb xauth dbus-x11 swtpm openssl libssl-dev libssl3t64 openssl-provider-legacy \
 && rm -rf /var/lib/apt/lists/*

# Node.js from the official binaries (Playwright needs a current one).
# pipefail: a failed download must not be hidden by the pipe into tar.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eu; \
    case "$(dpkg --print-architecture)" in amd64) arch=x64 ;; arm64) arch=arm64 ;; *) exit 1 ;; esac; \
    test -n "$NODE_VERSION"; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${arch}.tar.xz" \
      | tar -xJ -C /usr/local --strip-components=1 --exclude='*.md' --exclude=LICENSE

# Playwright with Chromium and its system libraries. Keep the version equal to
# @playwright/test of the project, which then finds the browser in
# PLAYWRIGHT_BROWSERS_PATH.
RUN test -n "$PLAYWRIGHT_VERSION" \
 && npm install -g "playwright@${PLAYWRIGHT_VERSION}" \
 && playwright install --with-deps chromium \
 && rm -rf /var/lib/apt/lists/* /root/.npm

RUN test -n "$GOCOVER_COBERTURA_VERSION" && test -n "$GOTESTFMT_VERSION" \
 && go install github.com/boumenot/gocover-cobertura@${GOCOVER_COBERTURA_VERSION} \
 && go install github.com/gotesttools/gotestfmt/v2/cmd/gotestfmt@${GOTESTFMT_VERSION} \
 && go clean -cache -modcache
