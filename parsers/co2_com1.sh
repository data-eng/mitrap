#!/bin/bash

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
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

  # This should look like this:
  # CO2=   382 ppm
  # with DOS line termination, but it is often broken. Be strict.
  re='CO2=[[:space:]]*([0-9]+(\.[0-9]+)?)[[:space:]]*ppm'
  if [[ "$value" =~ $re ]]; then
    num="${BASH_REMATCH[1]}"
    #echo "x${value}x$num"
    if [[ "$num" =~ ^-?[0-9]+$ ]]; then
          num="${num}.0"  # Make integers float to avoid flux being quirky
    fi
  else
    #echo "y${value}y"
    continue
  fi

  write_query="co2,installation=${installation_name},instrument=${instrument_name} value=${num} ${timestamp_unix}"
  echo $write_query >> "${file_to_store}.lp"

done < "$file_to_process"
