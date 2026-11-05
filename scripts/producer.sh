#!/usr/bin/env bash

set -euo pipefail

mkdir -p data/staging data/incoming

temp_file="data/staging/orders.csv.part"
final_file="data/incoming/orders.csv"

printf 'order_id,amount\n' > "$temp_file"

for i in 1 2 3 4 5; do
    printf 'O%s,%s\n' "$i" "$((i * 100000))" >> "$temp_file"
    sleep 1
done

mv -T -- "$temp_file" "$final_file"

echo "File published: $final_file"