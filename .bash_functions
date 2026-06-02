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

find-port-and-launch() {
    START_PORT=3000
    PROGRAM="$1"
    PORT_ALIAS="$2"

    if [[ -z "$PROGRAM" ]]; then
        echo "Usage: find-port-and-launch <program_to_launch> [port_env_var_name (default: PORT)]"
        return 1
    fi

    for port in $(seq "$START_PORT" 65535); do
        # Check if port is in use (LISTEN state)
        if ! lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "Port $port is available. Launching $PROGRAM on port $port."
            if [[ -z "$PORT_ALIAS" ]]; then
                PORT=$port $PROGRAM &
                return 0
            else
                env "$PORT_ALIAS=$port" $PROGRAM &
                return 0
            fi
        fi
    done
    echo "No ports $START_PORT+ were open! Aborting..."
    return 1
}

git-open-branch-diffs() {
    origin_main_branch="$(git symbolic-ref refs/remotes/origin/HEAD)"
    echo "Opening all files with diffs against $origin_main_branch..."
    $EDITOR $(git diff --name-only $origin_main_branch...)
}

git-list-branch-file-diffs() {
    origin_main_branch="$(git symbolic-ref refs/remotes/origin/HEAD)"
    echo "Listing all files with diffs against $origin_main_branch..."
    echo "$(git diff --name-only $origin_main_branch...)"
}

git-list-branch-diffs() {
    origin_main_branch="$(git symbolic-ref refs/remotes/origin/HEAD)"
    echo "Listing all files with diffs against $origin_main_branch..."
    echo "$(git diff --name-only $origin_main_branch...)"
    echo ""
    git diff --color "$origin_main_branch"...
}
