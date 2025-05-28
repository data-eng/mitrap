#!/bin/bash

source ./execution_map.sh

timestamp="1748420258"

chron_defined_pth="/mnt/diff/$timestamp/"

echo $chron_defined_pth

key="mitrap006/sambashare/AE31/mitrap"

# Check and run the command
if [[ -n "${command_map[$key]}" ]]; then
    echo "Running: ${command_map[$key]}"
    eval "${command_map[$key]}" ARGSSSSS
else
    echo "Unknown command key: $key"
fi
