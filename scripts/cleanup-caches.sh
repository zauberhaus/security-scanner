#!/usr/bin/env bash
#
# Deletes GitHub Actions caches that were not used for a while.
#
#   scripts/cleanup-caches.sh [-n] [-d DAYS]
#
#   -n  dry run: only list what would be deleted
#   -d  delete caches last used more than DAYS days ago (default 2)
#
# Caches belong to the ref that wrote them and only that ref (and the default
# branch) can read them, so caches of release tags and of pull requests are
# rarely used again but still count against the 10 GB limit. GitHub evicts
# unused caches after 7 days or when the limit is exceeded; this clears them
# sooner. Needs gh with "actions: write" for the repository (GH_REPO or a
# checkout).

set -euo pipefail

DAYS=1
DRY_RUN=false

while getopts ":nd:h" opt; do
  case $opt in
    n) DRY_RUN=true ;;
    d) DAYS=$OPTARG ;;
    h) sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "usage: $(basename "$0") [-n] [-d DAYS]" >&2; exit 2 ;;
  esac
done
[[ $DAYS =~ ^[0-9]+$ ]] || { echo "error: invalid number of days '$DAYS'" >&2; exit 2; }

repo=${GH_REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}
cutoff=$(( $(date +%s) - DAYS * 86400 ))

caches=$(gh api --paginate "repos/$repo/actions/caches?per_page=100" --jq '.actions_caches[]' | jq -s '.')
total=$(jq 'map(.size_in_bytes) | add // 0' <<< "$caches")
echo "==> $(jq length <<< "$caches") caches, $((total / 1048576)) MB"

freed=0
count=0
while IFS=$'\t' read -r id size ref key; do
  count=$((count + 1))
  freed=$((freed + size))
  if $DRY_RUN; then
    echo "    would delete $id ($((size / 1048576)) MB, $ref, ${key:0:60})"
  else
    echo "    deleting $id ($((size / 1048576)) MB, $ref, ${key:0:60})"
    gh api -X DELETE "repos/$repo/actions/caches/$id" --silent
  fi
done < <(jq -r --argjson cutoff "$cutoff" \
  '.[] | select((.last_accessed_at | sub("\\.[0-9]+"; "") | fromdateiso8601) < $cutoff)
       | [.id, .size_in_bytes, .ref, .key] | @tsv' <<< "$caches")

echo "==> $count caches, $((freed / 1048576)) MB $($DRY_RUN && echo 'would be ')deleted"
