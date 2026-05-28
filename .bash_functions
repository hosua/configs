#!/bin/bash

kill-port() {
    if [ -z "$1" ]; then
        echo "Usage: kill-port <port>"
        return 1
    fi
    pid=$(lsof -t -i:"$1")
    if [ -z "$pid" ]; then
        echo "No process found on port $1"
        return 1
    fi
    echo "Killing process $pid on port $1"
    kill "$pid"
}

git-open-branch-wdiffs() {
    origin_main_branch="$(git symbolic-ref refs/remotes/origin/HEAD)"
    echo "Opening all files with diffs against $origin_main_branch..."
    $EDITOR $(git diff --name-only $origin_main_branch...)
}

git-list-branch-diffs() {
    origin_main_branch="$(git symbolic-ref refs/remotes/origin/HEAD)"
    echo "Listing all files with diffs against $origin_main_branch..."
    echo "$(git diff --name-only $origin_main_branch...)"
}
