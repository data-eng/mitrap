#!/bin/bash

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val"
}

# /mnt/incoming/mitrap000/CO2/Data/COM2_Log_*.txt

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

while IFS=',' read -r date time value; do

  timestamp="$date $time"
  timestamp_unix=$(date -d "$timestamp" +%s)000000000

  # Remove square brackets from value
  value="${value#[}"
  value="${value%]}"

  echo "Timestamp : $timestamp_unix"
  echo "Value     : $value"

  # The installation name and instrument may include spaces and other invalid
  # (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
  # to clean them
  installation_name=$(escape_tag_value "$installation_name")
  instrument_name=$(escape_tag_value "$instrument_name")

  write_query="co2,installation=${installation_name},instrument=${instrument_name} value=$value $timestamp_unix"
  echo $write_query >> "$file_to_store"

 done < "$file_to_process"
