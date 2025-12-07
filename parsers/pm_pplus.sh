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

echo "ENV ae31: $BINDIR $instrument_tz"

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
station_name=$(escape_tag_value "$station_name")
instrument_name=$(escape_tag_value "$instrument_name")

# Re-format the cvs into the columns expected by pm25.py
tail +5 "${file_to_process}" > "${file_to_process}_temp1.csv"
python3 ${BINDIR}/pm_pplus.py "${file_to_process}_temp1.csv" "${station_name}" "${instrument_name}" "${file_to_process}_temp2.csv"

# Perform the PM calculations and write out the CSV
python3 ${BINDIR}/pm25.py "${file_to_process}_temp2.csv" "${file_to_store}.csv"

# Make the influx line with PM2.5 value only
cat ${file_to_store}.csv | tail +2 | cut -d ',' -f 1,4 | (while IFS=',' read -r datetime pm25; do
  timestamp_unix=$(TZ="${instrument_tz}" date -d "$datetime" +%s%N)
  datetime_tz=$(TZ="${instrument_tz}" date --rfc-3339=seconds -d "$datetime")
  write_query="pm,installation=${station_name},instrument=${instrument_name} pm25=${pm25} ${timestamp_unix}"
  echo $write_query >> "${file_to_store}.lp"
done)

exit 0

