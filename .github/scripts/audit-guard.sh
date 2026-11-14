#!/usr/bin/env bash
# Does the whole-library audit have anything new to read? (unit `tooling: the nightly
# skips unless what it reads changed`, Scott 2026-11-14: "we should also be good
# citizens and stop hammering github".)
#
#   audit-guard.sh <workflow file> <sha of the last whole-library run that succeeded> <HEAD>
#
# Prints one line, `skip: ...` or `audit: ...`. The paths it compares are the workflow's own
# `on.push.paths`, read from the workflow file, so the filter that starts a push's audit and
# the guard that spares a night's are one list. In doubt it audits: no run found, that commit
# not in this clone or not an ancestor of HEAD, no paths listed, or the comparison failing.
set -u
wf=$1 last=${2:-} head=$3

[ -n "$last" ] || { echo "audit: no whole-library run has succeeded"; exit 0; }
git cat-file -e "${last}^{commit}" 2>/dev/null || { echo "audit: $last is not in this clone"; exit 0; }
git merge-base --is-ancestor "$last" "$head" 2>/dev/null || { echo "audit: $last is not an ancestor of $head"; exit 0; }

paths=$(awk '/^  push:/{p=1; next} p && /^    paths:/{q=1; next} q && /^      - /{print; next} q{exit}' "$wf" \
        | sed -e "s/^      - *//" -e "s/ *#.*$//" -e "s/^'//" -e "s/'$//")
[ -n "$paths" ] || { echo "audit: $wf lists no push paths"; exit 0; }

specs=()
while IFS= read -r p; do specs+=(":(glob)$p"); done <<< "$paths"
changed=$(git diff --name-only "$last" "$head" -- "${specs[@]}" 2>/dev/null) || { echo "audit: the comparison failed"; exit 0; }

if [ -n "$changed" ]; then
  n=$(printf '%s\n' "$changed" | wc -l | tr -d ' ')
  echo "audit: $(printf '%s\n' "$changed" | head -1) changed since $last ($n file(s) under the audit's paths)"
else
  echo "skip: nothing the audit reads changed since $last"
fi
