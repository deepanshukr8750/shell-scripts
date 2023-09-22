#!/bin/bash

# Function to find and kill zombie processes
kill_zombies() {
    # Get the list of zombie process IDs
    zombie_pids=$(ps -eo pid,state | awk '$2=="Z" {print $1}')

    if [ -z "$zombie_pids" ]; then
        echo "No zombie processes found."
    else
        echo "Killing zombie processes..."
        # Iterate over each zombie process ID and kill it
        for pid in $zombie_pids; do
            echo "Killing zombie process with PID: $pid"
            kill -9 "$pid"
        done
        echo "All zombie processes killed."
    fi
}

# Call the function to kill zombie processes
kill_zombies
