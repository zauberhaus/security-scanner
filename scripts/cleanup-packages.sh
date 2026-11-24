#!/usr/bin/env bash
#
# Deletes old versions of the container packages on ghcr.io, keeping the two
# newest tagged versions (the latest release and the one before) of each.
#
#   scripts/cleanup-packages.sh [-n] [-k COUNT] [PACKAGE...]
#
#   -n  dry run: only list what would be deleted
#   -k  number of tagged versions to keep per package (default 2)
#
# Without PACKAGE, the packages of this repository are cleaned. Needs gh (with
# packages write access) and docker (logged in to ghcr.io, to read manifests).
#
# Versions tagged buildcache-* hold the BuildKit layer cache of the release
# builds: they are neither counted as releases nor deleted.
#
# A multi-arch image is made of several versions: the tagged index plus its
# untagged children (per-architecture images and attestations). The children of
# every kept version are kept too, otherwise the image would break. Untagged
# versions younger than GRACE_HOURS are kept as well: a release build pushes
# its children before the index that references them exists.

set -euo pipefail

KEEP=2
GRACE_HOURS=${GRACE_HOURS:-24}
DRY_RUN=false
PACKAGES=(security-scanner go-test-runner wails3-builder)

while getopts ":nk:h" opt; do
  case $opt in
    n) DRY_RUN=true ;;
    k) KEEP=$OPTARG ;;
    h) sed -n '3,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "invalid option: -$OPTARG" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] && PACKAGES=("$@")

OWNER=${OWNER:-$(gh repo view --json owner --jq .owner.login)}
OWNER=$(tr '[:upper:]' '[:lower:]' <<< "$OWNER")
if [ "$(gh api "users/$OWNER" --jq .type)" = Organization ]; then
  BASE=orgs/$OWNER
else
  BASE=users/$OWNER
fi

# children prints a digest and, recursively, the digests of all manifests it
# references.
children() {
  local image=$1 digest=$2 raw child
  echo "$digest"
  raw=$(docker buildx imagetools inspect --raw "$image@$digest" 2>/dev/null) || return 0
  for child in $(jq -r '.manifests[]?.digest' <<< "$raw"); do
    children "$image" "$child"
  done
}

for pkg in "${PACKAGES[@]}"; do
  image=ghcr.io/$OWNER/$pkg
  echo "==> $image"

  if ! versions=$(gh api --paginate "$BASE/packages/container/$pkg/versions?per_page=100" \
      --jq '.[] | {id, name, created_at, tags: (.metadata.container.tags // [])}' 2>/dev/null); then
    echo "    package not found, skipping"
    continue
  fi
  [ -n "$versions" ] || { echo "    no versions"; continue; }

  # The newest tagged versions, and everything they reference, are kept.
  kept=$(jq -rs --argjson n "$KEEP" \
    'map(select((.tags | length > 0) and (.tags | any(startswith("buildcache-")) | not))) | sort_by(.created_at) | reverse | .[:$n][] | .name' <<< "$versions")
  protected=$(for d in $kept; do children "$image" "$d"; done | sort -u)
  echo "    keeping: $(tr '\n' ' ' <<< "$kept" | sed 's/sha256:\([0-9a-f]\{12\}\)[0-9a-f]*/\1/g')"

  jq -c --arg protected "$protected" --argjson grace "$GRACE_HOURS" \
    'select(($protected | split("\n")) as $p | (.name | IN($p[]) | not))
     | select(.tags | any(startswith("buildcache-")) | not)
     | select((.created_at | fromdateiso8601) < (now - $grace * 3600))' <<< "$versions" |
  while IFS= read -r v; do
    id=$(jq -r .id <<< "$v")
    label=$(jq -r '(.tags | join(",")) as $t | "\(.name[0:19]) \(if $t == "" then "untagged" else $t end)"' <<< "$v")
    if $DRY_RUN; then
      echo "    would delete $id ($label)"
    else
      echo "    deleting $id ($label)"
      gh api -X DELETE "$BASE/packages/container/$pkg/versions/$id"
    fi
  done
done
