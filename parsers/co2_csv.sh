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

echo "ENV co2_csv: $BINDIR $instrument_tz"

echo "Datetime,CO2_ppm,Temperature_C" > "${file_to_process}.temp"
cat "${file_to_process}" | grep -v '^#' | sed 's|^"\([^"]*\)" \([^ ]*\) \(.*\)$|\1,\2,\3|' >> "${file_to_process}.temp"

python3 ${BINDIR}/co2.py "${file_to_process}.temp" "${station_name}" "${instrument_name}" "${instrument_tz}" '%Y-%m-%d %H:%M:%S' > "${file_to_store}.lp"

