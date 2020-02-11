#!/usr/bin/env bash

set -e -x

git diff-index --quiet HEAD
files_changed=$?
if [ $files_changed -ne 0 ]; then
    echo "git_commit.sh detected new build traces. git status:"
    git status
    git add build_traces
    git commit -m "add new puppet-agent-${BRANCH} traces"
    git push origin $PIPELINE_BRANCH
else
    echo "NO additional build_trace files. Job Complete"
    exit 0
fi
