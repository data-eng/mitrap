#!/bin/bash

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

if [[ x"$5" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
station_name=$3
instrument_name=$4
instrument_tz=$5

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV co2_com1: $BINDIR $instrument_tz"

station_name_lp=$(escape_tag_value "$station_name")
instrument_name_lp=$(escape_tag_value "$instrument_name")

echo "datetime,station_name,instrument_name,num_data_col,num_meta_col,co2" > "${file_to_store}.csv"

while IFS=',' read -r date time rest; do

  # Only accept lines where date and time match expected formats
  if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || [[ ! "$time" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    continue
  fi

  datetime="$date $time"

  if timestamp_unix=$(TZ="${instrument_tz}" date -d "$datetime" +%s%N 2>/dev/null); then
    datetime_tz=$(TZ="${instrument_tz}" date --rfc-3339=seconds -d "$datetime")
  else
    echo "Failed to parse datetime: $datetime — skipping line."
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

  echo "${datetime_tz},${station_name},${instrument_name},1,0,${num}" >> "${file_to_store}.csv"
  echo "co2,installation=${station_name_lp},instrument=${instrument_name_lp} value=${num} ${timestamp_unix}" >> "${file_to_store}.lp"

done < "$file_to_process"

