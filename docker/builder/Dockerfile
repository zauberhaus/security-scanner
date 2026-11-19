# Wails build image: Go, wails3 and garble, the GUI libraries, the Windows
# installer maker and the AppImage tooling, installed once instead of on every
# run. The versions come from scripts/builder-tools.env.
#
# .github/workflows/builder.yml builds it for linux/amd64 and linux/arm64 on
# native runners when a release is published. To pick up newer packages, change
# the REFRESH line.

# The Go release of go.mod ("1.27" is the latest 1.27.x).
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION} AS go

FROM ubuntu:26.04

ARG WAILS_VERSION=latest
ARG GARBLE_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive
# Change to rebuild the image with the current packages and tools.
ENV REFRESH=1

# Not pinned (DL3008): Ubuntu drops old package versions, so a pin would break
# the build.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git file zip xz-utils squashfs-tools \
        build-essential pkg-config libgtk-4-dev libwebkitgtk-6.0-dev \
        nsis \
    && rm -rf /var/lib/apt/lists/*

COPY --from=go /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:$PATH

# The task runner and the obfuscator, as in the macOS jobs. Their sources and
# caches are not kept in the image.
RUN test -n "$WAILS_VERSION" && test -n "$GARBLE_VERSION" \
    && GOBIN=/usr/local/bin go install "github.com/wailsapp/wails/v3/cmd/wails3@${WAILS_VERSION}" \
    && GOBIN=/usr/local/bin go install "mvdan.cc/garble@${GARBLE_VERSION}" \
    && go clean -cache -modcache

# What `wails3 generate appimage` downloads on every run if it is not in its
# build directory: linuxdeploy, for this machine's architecture. The workflow
# copies it there.
#
# A tagged release, checked against the SHA-256 of the file it shipped with,
# not the "continuous" build: whatever that tag serves on the day the image is
# rebuilt would otherwise end up in every AppImage of the release. To
# upgrade, change the tag and both checksums together (from the release page,
# or sha256sum of the downloaded files).
ARG LINUXDEPLOY_VERSION=1-alpha-20251107-1
ARG LINUXDEPLOY_SHA256_X86_64=c20cd71e3a4e3b80c3483cef793cda3f4e990aca14014d23c544ca3ce1270b4d
ARG LINUXDEPLOY_SHA256_AARCH64=620095110d693282b8ebeb244a95b5e911cf8f65f76c88b4b47d16ae6346fcff
# pipefail: a failed checksum must not be hidden by the pipe.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eu; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) sha256="$LINUXDEPLOY_SHA256_X86_64" ;; \
        aarch64) sha256="$LINUXDEPLOY_SHA256_AARCH64" ;; \
        *) echo "no linuxdeploy checksum for $arch" >&2; exit 1 ;; \
    esac; \
    mkdir -p /opt/appimage; \
    file="/opt/appimage/linuxdeploy-${arch}.AppImage"; \
    curl -fsSL -o "$file" \
        "https://github.com/linuxdeploy/linuxdeploy/releases/download/${LINUXDEPLOY_VERSION}/linuxdeploy-${arch}.AppImage"; \
    echo "${sha256}  ${file}" | sha256sum -c -; \
    chmod +x "$file"
