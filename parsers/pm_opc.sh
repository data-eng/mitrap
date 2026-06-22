#!/bin/bash

file_to_process=$1
file_to_store=$2
station_name=$3
instrument_name=$4
instrument_tz=$5

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV pm_opc: $BINDIR $instrument_tz"

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

# The rule 

# Re-format the cvs into the columns expected by pm25.py

# pm25.py assumes headerless csv
#echo "dt,installation,instrument,0.253,0.298,0.352,0.414,0.488,0.576,0.679,0.800,0.943,1.112,1.310,1.545,1.821,2.146,2.530,2.982,3.515,4.144,4.884,5.757,6.787,8.000,9.430,11.12,13.10,15.45,18.21,21.46,25.30,29.82,35.15" > "${file_to_store}.temp1"

tail +16 "${file_to_process}" | tr '\t' ',' |\
	sed "s@^\([0-9][0-9]\).\([0-1][0-9]\).20\([0-9][0-9]\) \([0-9:]*\),@20\3-\2-\1 \4,${station_name},${instrument_name},@" > "${file_to_store}.temp1"


# Perform the PM calculations and write out the CSV
python3 ${BINDIR}/pm25.py "${file_to_store}.temp1" "${file_to_store}.csv"

# Make the influx line with PM2.5 value only
stn=$(escape_tag_value "$station_name")
ins=$(escape_tag_value "$instrument_name")
cat ${file_to_store}.csv | tail +2 | cut -d ',' -f 1,4 | (while IFS=',' read -r datetime pm25; do
  timestamp_unix=$(TZ="${instrument_tz}" date -d "$datetime" +%s%N)
  datetime_tz=$(TZ="${instrument_tz}" date --rfc-3339=seconds -d "$datetime")
  write_query="pm,installation=${stn},instrument=${ins} pm25=${pm25} ${timestamp_unix}"
  echo $write_query >> "${file_to_store}.lp"
done)

exit 0

