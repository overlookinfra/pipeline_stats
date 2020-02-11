#!/usr/bin/env bash

set -e -x

git status

files_changed=$(( $(git ls-files --others --exclude-standard -- build_traces | wc -l) ))
if [ $files_changed -ne 0 ]; then
    echo "** git_commit.sh ** detected new build traces. Committing to git repo..."
    git add build_traces
    git commit -m "add new puppet-agent-${BRANCH} traces"
    git push origin $PIPELINE_STATS_BRANCH
else
    echo "NO additional build_trace files. Job Complete"
    exit 0
fi
