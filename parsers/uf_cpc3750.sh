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

python3 ${BINDIR}/parsers/uf_cpc3750.py "${file_to_process}" "${file_to_store}.csv" "${installation_name}" "${instrument_name}" "Europe/Rome"

bash ${BINDIR}/parsers/uf_valve_finder.sh "${file_to_store}.csv" "${file_to_store}_valve.csv" "${installation_name}"

python3 ${BINDIR}/parsers/uf_cpc3772_lp.py "${file_to_store}_valve.csv" "${installation_name}" "${instrument_name}" > "${file_to_store}.lp"

