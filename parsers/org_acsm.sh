#!/bin/bash

SPOOL=/mnt/spool

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

echo "ENV org_acsm: $BINDIR $instrument_tz"

python3 ${BINDIR}/org_acsm.py "${file_to_process}" "${station_name}" "${instrument_name}" "${file_to_store}.csv" > "${file_to_process}.temp.lp"

# ACSM files in new/ are complete files, not incremental.
# To avoid re-loading all timepoints, spool the number of
# lines in the CSV that have already been loaded.

#if [[ -f "${SPOOL}/acsm_${installation_name}" ]]; then
#    num_lines=$(cat "${SPOOL}/acsm_${installation_name}" | wc -l)
#else
#    num_lines=0
#fi

#wc -l "${file_to_process}.temp.lp" > "${SPOOL}/acsm_${installation_name}"

#cat "${file_to_process}.temp.lp" | tail +${num_lines} > "${file_to_store}.lp"
mv "${file_to_process}.temp.lp" "${file_to_store}.lp"


