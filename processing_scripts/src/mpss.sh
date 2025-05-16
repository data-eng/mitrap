#!/bin/bash

if [[ x"$1" == x || x"$2" == x ]]; then explode; fi

mitrap_station=$1
BUCKET=$2

DIRECTORY="/mnt/incoming/$mitrap_station/sambashare/MPSS_ATH/inverted"

for file in "$DIRECTORY"/*.inv; do

  filename=$(basename "$file")
  date_str=$(echo "$filename" | grep -oP '\d{8}')  # Extract YYYYMMDD
  date_fmt="${date_str:0:4}-${date_str:4:2}-${date_str:6:2}"

  echo $date_fmt

  # Read lines in pairs
  paste - - < "$file" | while IFS=$'\t' read -r line1 line2; do
    # Read first 4 common values
    read -r time1 temp1 press1 other1 rest1 <<<"$(echo "$line1" | awk '{print $1, $2, $3, $4, substr($0, index($0,$5))}')"
    read -r time2 temp2 press2 other2 rest2 <<<"$(echo "$line2" | awk '{print $1, $2, $3, $4, substr($0, index($0,$5))}')"

    # Assert equality
    if [[ "$time1" != "$time2" || "$temp1" != "$temp2" || "$press1" != "$press2" || "$other1" != "$other2" ]]; then
      continue
    fi

    # Convert time_frac to UNIX timestamp
    day_seconds=$(awk -v f="$time1" 'BEGIN {printf "%.0f", f * 86400}')
    timestamp_unix=$(date -d "$date_fmt 00:00:00 + $day_seconds seconds" +%s)000000000

    # Convert nanometer (nm) headers to field names
    IFS=$'\t' read -r -a nm_keys <<< "$(echo "$rest1")"
    IFS=$'\t' read -r -a nm_vals <<< "$(echo "$rest2")"

    fields="temp_C=${temp1},pressure_hPa=${press1},other=${other1}"

    for i in "${!nm_keys[@]}"; do
      key="${nm_keys[$i]}"
      val="${nm_vals[$i]}"

      key_fixed="nm$(echo "$key" | awk -F. '{printf "%s_%s", $1, $2}')"
      fields="${fields},${key_fixed}=${val}"
    done

    influx_line="mpss ${fields} ${timestamp_unix}"

    echo "$influx_line"

  done
done