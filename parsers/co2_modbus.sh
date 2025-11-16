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

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$installation_name")
instrument_name=$(escape_tag_value "$instrument_name")

echo "Datetime,CO2_ppm,Temperature_C" > "${file_to_process}.temp"
cat "${file_to_process}" | iconv -f iso-8859-1 | sed 's|\([^;]*\); CO2=\(.*\) ppm; T=\(.*\) .*$|\1,\2,\3|' >> "${file_to_process}.temp"

python3 ${BINDIR}/parsers/co2.py "${file_to_process}.temp" "${installation_name}" ${instrument_name} > "${file_to_store}.lp"

