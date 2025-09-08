#!/bin/bash

START_COL=2

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

# /mnt/incoming/mitrap000/OPS/*.csv

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$installation_name")
instrument_name=$(escape_tag_value "$instrument_name")

declare -a headers
DATA_SECTION=false

# Function to trim whitespace
trim() {
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

while IFS= read -r line; do

  # Skip empty lines
  [[ -z "$line" ]] && continue

  # Detect and store column headers
  if [[ "$line" == Sample\ #,* ]]; then
    IFS=',' read -ra headers <<< "$line"
    DATA_SECTION=true
    continue
  fi

  if [[ "$DATA_SECTION" == true && "$line" =~ ^[0-9]+, ]]; then
    IFS=',' read -ra values <<< "$line"

    sample_id="${values[0]}"
    date="${values[1]}"
    time="${values[2]}"
    timestamp_unix="$(date -d "$date $time" +%s)000000000"

    fields=""
    csv_cols=""
    for i in "${!headers[@]}"; do
      if [[ i -le ${START_COL} ]]; then continue; fi
      key=$(escape_tag_value "${headers[$i]}")
      key=$(echo  "$key" | sed 's/(..*)//g' | tr '.' '_')
      if [[ $key =~ ^[0-9] ]] ; then key="nm_$key" ; fi
      value="${values[$i]}"
      [[ "$value" == "NA" || "$value" == "" ]] && continue
      if [[ "$fields" != "" ]]; then
        fields+=",${key}=${value}"
	csv_cols+=",${value}"
      else 
        fields="${key}=${value}"
	csv_cols="${value}"
      fi
    done

    # Influx line
    write_query="ops,installation=${installation_name},instrument=${instrument_name} ${fields} $timestamp_unix"
    echo $write_query >> "${file_to_store}.lp"

    # CSV line
    echo "${timestamp_unix},${installation_name},${instrument_name},NA,${csv_cols}" >> "${file_to_store}.csv"
    

  fi

done < "$file_to_process"
