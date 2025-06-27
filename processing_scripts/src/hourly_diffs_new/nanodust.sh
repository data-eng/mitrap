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

tail -n +2 "$file_to_process" | while IFS=',' read -r time_pc time_dut mode pn gmd tet cabt tpe tze trf tse fre sp dp sf df uhv; do

  timestamp_unix=$(date -d "$time_pc" +%s)000000000

  write_query="nanodust,installation=${installation_name},instrument=${instrument_name} mode=$mode,pn=$pn,gmd=$gmd $timestamp_unix"

  echo $write_query >> "$file_to_store"

done

