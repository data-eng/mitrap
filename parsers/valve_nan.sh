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

echo "ENV valve_nan: $BINDIR $instrument_tz"

cat "${file_to_process}" | sed 's| b|,|' | sed 's|\\r\\n||' | tr -d \' > "${file_to_process}.temp"

python3 ${BINDIR}/uf_valve.py "${file_to_process}.temp" "${file_to_store}.csv" "${station_name}" "${instrument_name}" "${instrument_tz}" "nan" > "${file_to_store}.lp"

