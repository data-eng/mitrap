#!/bin/bash

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val"
}

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

installation_name=$(escape_tag_value "$installation_name")
instrument_name=$(escape_tag_value "$instrument_name")


while IFS=',' read -r date time rest; do

  # Only accept lines where date and time match expected formats
  if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || [[ ! "$time" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    continue
  fi

  timestamp="$date $time"

  if epoch_s=$(date -d "$timestamp" +%s 2>/dev/null); then
    timestamp_unix="${epoch_s}000000000"
  else
    echo "Failed to parse timestamp: $timestamp — skipping line."
    continue
  fi

  value="$rest"

  value="${value#"${value%%[![:space:]]*}"}"    # ltrim
  value="${value%"${value##*[![:space:]]}"}"    # rtrim

  # Remove surrounding square brackets (if present)
  value="${value#[}"
  value="${value%]}"

  # Extract the numeric part (integer or decimal) from the value
  if [[ "$value" =~ ([0-9]+(\.[0-9]+)?) ]]; then
    num="${BASH_REMATCH[1]}"
  else
    continue
  fi

  write_query="co2,installation=${installation_name},instrument=${instrument_name} value=${num} ${timestamp_unix}"
  echo "$write_query" >> "$file_to_store"

done < "$file_to_process"
