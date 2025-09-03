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

regex='^-?[0-9]+(\.[0-9]+)?$'

while IFS=',' read -r timestamp datestr timestr nm370 nm450 nm520 nm590 nm660 nm880 nm950 flow rest; do

    timestamp_unix=$(date -d "$timestamp" +%s)000000000

    # Make integers float to avoid flux being quirky
    for var in nm370 nm450 nm520 nm590 nm660 nm880 nm950; do
      if [[ "${!var}" =~ ^-?[0-9]+$ ]]; then
        printf -v "$var" '%s.0' "${!var}"
      fi
    done

    write_query="ae31,installation=${installation_name},instrument=${instrument_name} date_str=$datestr,time_str=$timestr,nm370=$nm370,nm450=$nm450,nm520=$nm520,nm590=$nm590,nm660=$nm660,nm880=$nm880,nm950=$nm950,flow=$flow $timestamp_unix"

    echo $write_query >> "$file_to_store"

 done < "$file_to_process"
