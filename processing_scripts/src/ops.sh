#!/bin/bash

# /mnt/incoming/mitrap000/OPS/*.csv

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

declare -A metadata
declare -a midpoints
declare -a headers
DATA_SECTION=false
MIDPOINT_START_COL=17

# Function to trim whitespace
trim() {
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

while IFS= read -r line; do

  # Skip empty lines
  [[ -z "$line" ]] && continue

  # Metadata parsing (before column headers)
  if [[ "$line" != Sample\ #,* && "$DATA_SECTION" == false ]]; then
    key=$(echo "$line" | cut -d',' -f1)
    value=$(echo "$line" | cut -d',' -f2-)
    key=$(trim "$key")
    value=$(trim "$value")
    metadata["$key"]="$value"
    continue
  fi

  # Detect and store column headers
  if [[ "$line" == Sample\ #,* ]]; then
    IFS=',' read -ra headers <<< "$line"
    DATA_SECTION=true
    continue
  fi

  # Midpoints line 
  if [[ "$line" == *Midpoint\ Diameter* ]]; then
    IFS=',' read -ra temp <<< "$line"
    midpoints=("${temp[@]:$MIDPOINT_START_COL}")
    continue
  fi

  if [[ "$DATA_SECTION" == true && "$line" =~ ^[0-9]+, ]]; then
    IFS=',' read -ra values <<< "$line"

    sample_id="${values[0]}"
    date="${values[1]}"
    time="${values[2]}"
    timestamp_unix="$(date -d "$date $time" +%s)000000000"

    tags="sample_id=$sample_id"
    for key in "${!metadata[@]}"; do
      tag_key=$(echo "$key" | tr ' ' '_' | tr -d '()')
      tag_value=$(echo "${metadata[$key]}" | tr ' ' '_')
      tags+=",${tag_key}=${tag_value}"
    done

    fields=""
    for i in "${!headers[@]}"; do
      key=$(echo "${headers[$i]}" | tr ' ' '_' | tr -d '()#/.�')
      value="${values[$i]}"
      [[ "$value" == "NA" || "$value" == "" ]] && continue
      [[ "$fields" != "" ]] && fields+=","
      fields+="${key}=${value}"
    done

    for i in "${!midpoints[@]}"; do
      idx=$((MIDPOINT_START_COL + i))
      value="${values[$idx]}"
      midpoint=$(printf "%.3f" "${midpoints[$i]}")
      [[ "$value" == "" || "$value" == "NA" ]] && continue
      fields+=",nm_${midpoint}=${value}"
    done

    write_query='ops,installation="'"$installation_name"'",instrument="'"${instrument_name}"'"'" ${tags} ${fields} $timestamp_unix"
    echo $write_query >> "$file_to_store"

  fi

done < "$file_to_process"
