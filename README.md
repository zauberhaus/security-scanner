# security-scanner

Container image with Go and the security tools [govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck),
[gosec](https://github.com/securego/gosec) and [gitleaks](https://github.com/gitleaks/gitleaks),
published to the GitHub Container Registry.

| Image | Base |
| --- | --- |
| `ghcr.io/<owner>/security-scanner:latest` | `golang` (Debian) |
| `ghcr.io/<owner>/security-scanner:latest-alpine` | `golang-alpine` |

Both are built for `linux/amd64` and `linux/arm64`. Version tags (`vX.Y.Z`) produce `X.Y.Z` and `X.Y` tags.

## Layout

| Path | Purpose |
| --- | --- |
| `docker/security/Dockerfile`, `Dockerfile.alpine` | The images |
| `scripts/security-tools.env` | Pinned tool versions, passed as build arguments |
| `scripts/build.sh` | Local build, optional push (`-p`), alpine variant (`-a`) |
| `.github/workflows/build.yml` | Builds on PRs; pushes on `main`, tags and weekly |

## Use

```sh
docker run --rm -v "$PWD":/src -w /src ghcr.io/<owner>/security-scanner govulncheck ./...
```

## License

Apache License 2.0, see [LICENSE](LICENSE).
