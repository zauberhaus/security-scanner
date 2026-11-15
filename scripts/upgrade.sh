#!/usr/bin/env bash
#
# Set the tool versions in scripts/security-tools.env to the latest stable
# releases, as the Go module proxy reports them (pre-releases are ignored).
#
#   scripts/upgrade.sh      update the file and show what changed
#   scripts/upgrade.sh -n   only show what would change
#
# Review the change, then build (scripts/build.sh) and commit it.
set -euo pipefail

ENV_FILE="$(dirname "$0")/security-tools.env"
PROXY=${GOPROXY_URL:-https://proxy.golang.org}
DRY_RUN=false

while getopts "nh" opt; do
  case "$opt" in
    n) DRY_RUN=true ;;
    h) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) exit 2 ;;
  esac
done

command -v curl >/dev/null || { echo "error: curl is required" >&2; exit 1; }
[ -w "$ENV_FILE" ] || { echo "error: cannot write $ENV_FILE" >&2; exit 1; }

# latest MODULE: the latest stable version of a Go module.
latest() {
  local version
  version=$(curl -fsS "$PROXY/$1/@latest" | sed -n 's/.*"Version":"\([^"]*\)".*/\1/p') || return 1
  [[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "error: unexpected version '$version' for $1" >&2; return 1; }
  printf '%s\n' "$version"
}

changed=false
update() {
  local key=$1 module=$2 old new
  old=$(sed -n "s/^$key=//p" "$ENV_FILE")
  new=$(latest "$module")
  if [ "$old" = "$new" ]; then
    printf '%-20s %s (up to date)\n' "$key" "$old"
    return
  fi
  printf '%-20s %s -> %s\n' "$key" "${old:-unset}" "$new"
  changed=true
  if ! $DRY_RUN; then
    if grep -q "^$key=" "$ENV_FILE"; then
      sed -i.bak "s|^$key=.*|$key=$new|" "$ENV_FILE" && rm -f "$ENV_FILE.bak"
    else
      printf '%s=%s\n' "$key" "$new" >> "$ENV_FILE"
    fi
  fi
}

update GOVULNCHECK_VERSION golang.org/x/vuln
update GOSEC_VERSION github.com/securego/gosec/v2
update GITLEAKS_VERSION github.com/zricethezav/gitleaks/v8

if ! $changed; then
  echo "Nothing to upgrade."
elif $DRY_RUN; then
  echo "Dry run: $ENV_FILE not changed."
else
  echo "Updated $ENV_FILE. Build with scripts/build.sh before committing."
fi
