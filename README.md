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
| `.github/workflows/release-please.yml` | Release PR, `CHANGELOG.md` and `v*` tag via release-please |
| `.github/dependabot.yml` | Updates for the base images and the actions |
| `scripts/upgrade.sh` | Sets the tool versions to the latest stable releases |
| `scripts/release.sh` | Opens the PR, merges it and follows the release |

## Release

`main` is protected: nothing is pushed to it directly. Work on a branch (normally `dev`) with
[conventional commits](https://www.conventionalcommits.org/) and run:

```sh
scripts/release.sh            # test build, push the branch, PR into main, merge, wait for the release
scripts/release.sh -v 1.2.0   # force the version
```

The merge to `main` starts the *Release Check* workflow. release-please opens a release PR (version,
`CHANGELOG.md`), which the workflow merges once its checks pass. The resulting `vX.Y.Z` tag
makes *Build image* publish `X.Y.Z`, `X.Y` and the `-alpine` variants.

The workflow needs the repository secrets `RELEASE_APP_ID` and `RELEASE_APP_PRIVATE_KEY` of a
GitHub App with Contents and Pull requests write access (an app, not a token: its commits are signed).
The release PR must be allowed to merge, so the *Build image* check should be the only required one.

## Use

```sh
docker run --rm -v "$PWD":/src -w /src ghcr.io/<owner>/security-scanner govulncheck ./...
```

## License

Apache License 2.0, see [LICENSE](LICENSE).
