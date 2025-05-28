#!/bin/bash

if [[ x"$1" == x ]]; then exit 1; fi

SCRIPT_DIR="./src"
timestamp=$(date +"%Y%m%d_%H%M%S")

for script in "$SCRIPT_DIR"/*.sh; do
  if [[ -f "$script" ]]; then
    base_name=$(basename "$script" .sh)

    log_file="influx_log/${base_name}_log_${timestamp}.txt"

    echo "Running: $script"

    chmod +x "$script"
    sudo bash "$script" $1 $1 > "$log_file" 2>&1

    echo "Output written to: $log_file"
  fi
done
