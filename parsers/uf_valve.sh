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

echo "ENV uf_valve: $BINDIR $instrument_tz"

# No .lp file written. The .csv is read in by uf_cpc3772.py
# The data fetcher:
# (a) ensures that this is executed before uf_cpc3772.py
# (b) provides the filename of this csv to uf_cpc3772.py

python3 ${BINDIR}/uf_valve.py "${file_to_process}" "${file_to_store}.csv" "${station_name}" "${instrument_name}" > "${file_to_store}.lp"

