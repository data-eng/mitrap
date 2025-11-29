#!/bin/bash

BINDIR="/home/debian/live"

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

# No .lp file written. The .csv is read in by uf_cpc3772.py
# The data fetcher:
# (a) ensures that this is executed before uf_cpc3772.py
# (b) provides the filename of this csv to uf_cpc3772.py

python3 ${BINDIR}/parsers/uf_valve.py "${file_to_process}" "${file_to_store}.csv" "${installation_name}" "${instrument_name}" "Europe/Athens" > "${file_to_store}.lp"
