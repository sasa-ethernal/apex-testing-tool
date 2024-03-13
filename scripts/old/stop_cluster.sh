#!/bin/bash

# Loop until pgrep doesn't return any PIDs
while pgrep -f 'cardano-node run' >/dev/null; do
    # Capture the output of pgrep and append it to the pids array
    pids+=( $(pgrep -f 'cardano-node run') )
    # Sleep for a short duration before checking again
    for pid in "${pids[@]}"; do
        echo "$pid"
        kill "$pid"
    done
    sleep 1
done

