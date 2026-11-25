#!/usr/bin/env bash
# Tell the registry about an attempt made here: that it has started, or that it is finished and can be taken
# (encore-protocol docs/outside-runs.md).
#
#   tools/tell_registry.sh start PAPER
#   tools/tell_registry.sh attempt PAPER
#
# With GH_TOKEN, a token that may start the registry's workflows (encorescience/encore-runner has one, the secret
# ENCORE_INTAKE_TOKEN; a fork does not), it starts the registry's intake and waits for it, and fails if the
# registry refuses. Without one it writes, in the run's summary, a link to an "Outside attempt" issue on the
# registry with everything filled in, for a person to open.
set -euo pipefail
what=${1:?start or attempt}; paper=${2:?the paper\'s key}
registry=${REGISTRY:-encorescience/encore-registry}
run_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
case "$what" in
  start)   said="The attempt has started";  when="The attempt on $paper has started.";;
  attempt) said="The attempt is finished";  when="The attempt on $paper is finished.";;
  *) echo "::error::Not something to tell the registry: '$what'"; exit 1;;
esac

if [ -z "${GH_TOKEN:-}" ]; then
  q=$(python3 -c 'import sys, urllib.parse as u; print(u.urlencode({"template": "outside-attempt.yml", "title": f"Outside attempt: {sys.argv[2]}, {sys.argv[3].lower()}", "run": sys.argv[1], "paper": sys.argv[2], "what": sys.argv[3]}))' "$run_url" "$paper" "$said")
  {
    echo "## Tell the registry"
    echo
    echo "$when Tell the registry with [this issue](https://github.com/$registry/issues/new?$q), which has the run's address and the paper filled in. Someone at CatalystNeuro approves it, and the registry's intake comments on the issue."
  } >> "$GITHUB_STEP_SUMMARY"
  echo "::notice::$when Tell the registry with an Outside attempt issue (see the summary)."
  exit 0
fi

request="$GITHUB_REPOSITORY_OWNER-$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT-$what"
gh workflow run intake.yml -R "$registry" -f run_url="$run_url" -f what="$what" -f paper="$paper" -f request="$request"
id=
for _ in $(seq 30); do
  sleep 10
  id=$(gh run list -R "$registry" -w intake.yml -e workflow_dispatch -L 20 --json databaseId,displayTitle \
         --jq ".[] | select(.displayTitle == \"Intake: $request\") | .databaseId" | head -1)
  [ -z "$id" ] || break
done
[ -n "$id" ] || { echo "::error::The registry's intake did not start; tell it with an Outside attempt issue."; exit 1; }
echo "Intake: https://github.com/$registry/actions/runs/$id" >> "$GITHUB_STEP_SUMMARY"
gh run watch "$id" -R "$registry" --exit-status > /dev/null || {
  echo "::error::The registry refused: https://github.com/$registry/actions/runs/$id"; exit 1; }
case "$what" in
  start)   echo "The registry has recorded that this repository is attempting $paper." >> "$GITHUB_STEP_SUMMARY";;
  attempt) echo "The registry took the attempt as its branch attempt/$paper." >> "$GITHUB_STEP_SUMMARY";;
esac
