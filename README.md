# security-scanner

Container images for CI jobs, published to the GitHub Container Registry. The main one has Go and the
security tools [govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck),
[gosec](https://github.com/securego/gosec) and [gitleaks](https://github.com/gitleaks/gitleaks).

| Image | Contents | Source |
| --- | --- | --- |
| `ghcr.io/<owner>/security-scanner` | Go, govulncheck, gosec, gitleaks (`golang`, Debian) | `docker/security/Dockerfile` |
| `ghcr.io/<owner>/go-test-runner` | Go test tools: GTK, WebKit, Playwright, gocover-cobertura, gotestfmt | `docker/go-test-runner/Dockerfile` |
| `ghcr.io/<owner>/wails3-builder` | Wails build image: Go, wails3, garble, installer and AppImage tooling (Ubuntu) | `docker/wails3-builder/Dockerfile` |

All are built for `linux/amd64` and `linux/arm64` and tagged `X.Y.Z`, `X.Y`, `latest` and the commit
(`sha-…`) when a release is published. Only the two newest releases are kept (see *Cleanup*).

## Layout

| Path | Purpose |
| --- | --- |
| `docker/security/`, `docker/go-test-runner/`, `docker/wails3-builder/` | The images |
| `scripts/security-tools.env`, `go-test-runner-tools.env`, `wails3-builder-tools.env` | Tool versions, passed as build arguments |
| `scripts/build.sh` | Local build, optional push (`-p`), go-test-runner image (`-x`) |
| `scripts/tests.sh` | Runs the *Test* checks locally |
| `scripts/upgrade.sh` | Sets the tool versions to the latest stable releases |
| `scripts/release.sh` | Opens the PR, merges it and follows the release |
| `scripts/cleanup-packages.sh` | Deletes old image versions (`-n` for a dry run) |
| `.trivyignore` | Accepted Trivy findings, with the reason |

## Workflows

| Workflow | Runs | Purpose |
| --- | --- | --- |
| `test.yml` | every PR, push to `main` | *Test* check: `docker build --check` and hadolint (errors and warnings fail) on every Dockerfile |
| `security.yml` | every PR, push to `main` | *Security* check: Trivy and Checkov misconfiguration scans of the Dockerfiles |
| `codeql.yml` | every PR, push to `main`, weekly | CodeQL analysis of the workflows; the `main-checks` ruleset requires its results |
| `checks-gate.yml` | called by `release-please.yml` | Waits for the *Test*, *Security* and *CodeQL* jobs of the commit and fails if any failed, so nothing is released from a failing commit |
| `release-please.yml` | push to `main` | Release PR, `CHANGELOG.md`, tag and GitHub release via release-please |
| `security-scanner.yml`, `go-test-runner.yml`, `wails3-builder.yml` | release published | Build one image each natively on amd64 and arm64 runners (no QEMU), push by digest, then merge into one multi-arch tag |
| `cleanup.yml` | daily, manual | Deletes old image versions |

`.github/dependabot.yml` keeps the base images and the actions current.

## Release

`main` is protected: nothing is pushed to it directly. Work on a branch (normally `dev`) with
[conventional commits](https://www.conventionalcommits.org/) and run:

```sh
scripts/release.sh            # test build, push the branch, PR into main, merge, wait for the release
scripts/release.sh -v 1.2.0   # force the version
```

The merge to `main` starts the *Release Check* workflow. release-please opens a release PR (version,
`CHANGELOG.md`), which the workflow merges once its checks pass. The resulting `vX.Y.Z` release
makes the three build workflows publish their images with the tags above.

The workflow needs the repository secrets `RELEASE_APP_ID` and `RELEASE_APP_PRIVATE_KEY` of a
GitHub App with Contents and Pull requests write access (an app, not a token: its commits are signed).
The release PR must be allowed to merge, so the required checks must be the *Test* and *Security* jobs, which run on every pull request.

## Cleanup

*Clean up packages* runs daily and deletes old image versions of the three packages, keeping the two
newest tagged versions (the latest release and the one before). A multi-arch image consists of several
versions, so the children of a kept version are kept too, and untagged versions younger than 24 hours are
left alone because a release build creates them before the tag. Preview with `scripts/cleanup-packages.sh -n`
or run the workflow manually with *dry_run*. The packages must give the repository write access (package
settings, *Manage Actions access*).

## Use

```sh
docker run --rm -v "$PWD":/src -w /src ghcr.io/<owner>/security-scanner govulncheck ./...
```

## License

Apache License 2.0, see [LICENSE](LICENSE).
