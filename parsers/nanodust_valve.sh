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
bucket_name=$6

if [[ x${bucket_name} == x ]]; then
	bucket_name='mitrap006'
fi

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV nanodust: $BINDIR $instrument_tz"

echo "datetime,concentration_cc" > "${file_to_store}_temp"
# fix datetime from <date> <time> to <date>T<time>+00:00
# CAREFUL: This is a hack for UTC time only
cat "${file_to_process}" | tail +2 | cut -d, -f 1-2 | tr ' ' 'T' | sed 's|,|+00:00,|' >> "${file_to_store}_temp" 

bash ${BINDIR}/valve_finder.sh "${file_to_store}_temp" "${file_to_store}.csv" "${station_name}" "${bucket_name}"

python3 ${BINDIR}/uf_lp_maker.py "${file_to_store}.csv" "${station_name}" "${instrument_name}" > "${file_to_store}.lp"

