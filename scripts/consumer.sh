#!/usr/bin/env bash

set -euo pipefail

file="data/incoming/orders.csv"

for i in 1 2 3 4 5 6 7 8; do
    if [[ -f "$file" ]]; then
        echo "Consumer found published file: "
        cat "$file"
        exit 0
    fi

    echo "Waiting for published file..."
    sleep 1
done

echo "No published file found"