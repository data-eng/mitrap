#!/bin/bash

convert_custom_time_to_unix_ns() {
  local base_date="$1"
  local float_time="$2"

  local hour=$(awk -v t="$float_time" 'BEGIN { printf "%d", int(t) }')
  local min_fraction=$(awk -v t="$float_time" 'BEGIN { printf "%.6f", t - int(t) }')
  local minutes=$(awk -v f="$min_fraction" 'BEGIN { printf "%d", f * 60 }')
  local seconds_fraction=$(awk -v f="$min_fraction" 'BEGIN { printf "%.6f", (f * 60) - int(f * 60) }')
  local seconds=$(awk -v f="$seconds_fraction" 'BEGIN { printf "%d", f * 60 }')

  local datetime="${base_date} $(printf "%02d:%02d:%02d" "$hour" "$minutes" "$seconds")"

  epoch=$(date -d "$datetime" +%s)

  echo "${epoch}000000000"
}

clean_nm() {
  local raw_val="$1"

  # Normalize to numeric, trim trailing zeros but keep at least one decimal digit
  awk -v val="$raw_val" '
  BEGIN {
    split(val, parts, ".")
    int_part = parts[1]
    frac_part = parts[2]

    sub(/0+$/, "", frac_part)

    if (frac_part == "") {
      frac_part = "0"
    }

    printf "nm%s_%s\n", int_part, frac_part
  }'
}


if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments [station], [file_to_process], [timestamp_DD] or [file_to_store]." >> /home/mitrap/log/mpss.log
  exit 1
fi

station=$1
file_to_process=$2
timestamp_DD=$3
file_to_store=$4
dir_influx_log="/home/debian/src/mitrap/influx_log/$timestamp_DD/$station"
mkdir -p $dir_influx_log


filename=$(basename "$file_to_process")
date_str=$(echo "$filename" | grep -oP '\d{8}')  # Extract YYYYMMDD
date_fmt="${date_str:0:4}-${date_str:4:2}-${date_str:6:2}"

exec 3< "$file_to_process" 

while true; do
  read -r line1 <&3 || break
  read -r line2 <&3 || break
 
  # Parse line 1 nanometer (nm) headers
  read -ra fields1 <<< "$line1"
  read -ra fields2 <<< "$line2"

  # Both lines should have the same number of columns
  if [[ ${#fields1[@]} -ne ${#fields2[@]} ]]; then
    continue
  fi

  # Extract fixed columns
  time1="${fields1[0]}"; time2="${fields2[0]}"
  temp1="${fields1[1]}"; temp2="${fields2[1]}"
  press1="${fields1[2]}"; press2="${fields2[2]}"
  other1="${fields1[3]}"; other2="${fields2[3]}"

  # Assert common columns match
  if [[ "$time1" != "$time2" || "$temp1" != "$temp2" || "$press1" != "$press2" || "$other1" != "$other2" ]]; then
    continue
  fi

  timestamp_unix=$(convert_custom_time_to_unix_ns "$date_fmt" "$time1")

  fields="temp_C=${temp1},pressure_hPa=${press1},other=${other1}"

  # Loop over nm fields
  for ((i = 4; i < ${#fields1[@]}; i++)); do

    nm_raw="${fields1[$i]}"
    val="${fields2[$i]}"

    nm_raw=$(echo "$nm_raw" | tr -d '\n' | tr -d '\r')
    val=$(echo "$val" | tr -d '\n' | tr -d '\r')

    nm_name=$(clean_nm "$nm_raw")
    fields="${fields},${nm_name}=${val}"
  done

  write_query="smps_data ${fields} ${timestamp_unix}"
  echo $write_query >> "$dir_influx_log/$file_to_store.txt"

  done

exec 3<&-
