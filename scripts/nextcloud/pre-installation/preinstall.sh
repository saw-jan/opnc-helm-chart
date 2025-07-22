#!/bin/bash

set -eo pipefail

function wait_for_command() {
    local cmd="$1"
    local retries=12
    local delay=5

    for ((i = 0; i < retries; i++)); do
        if command -v "$cmd" >/dev/null; then
            return 0
        fi
        echo "Waiting for '$cmd' to be available..."
        sleep "$delay"
    done

    echo "Command '$cmd' not found after $((retries * delay)) seconds."
    exit 1
}

wait_for_command git
wait_for_command node
wait_for_command npm
wait_for_command composer
