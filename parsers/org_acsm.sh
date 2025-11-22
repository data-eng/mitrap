#!/bin/bash

BINDIR="/home/debian/live"
SPOOL=/mnt/spool

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

python3 ${BINDIR}/parsers/org_acsm.py "${file_to_process}" "${installation_name}" "${instrument_name}" "${file_to_store}.csv" > "${file_to_process}.temp.lp"

# ACSM files in new/ are complete files, not incremental.
# To avoid re-loading all timepoints, spool the number of
# lines in the CSV that have already been loaded.

if [[ -f "${SPOOL}/acsm_${installation_name}" ]]; then
    num_lines=$(cat "${SPOOL}/acsm_${installation_name}")
else
    num_lines=0
fi

num_lines=$((num_lines+1))

wc -l "${file_to_process}.temp.lp" > "${SPOOL}/acsm_${installation_name}"

cat "${file_to_process}.temp.lp" | tail +${num_lines} > "${file_to_store}.lp"

