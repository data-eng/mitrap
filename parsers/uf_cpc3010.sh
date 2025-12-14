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

echo "ENV uf_cpc3010: $BINDIR $instrument_tz"

# iconv to clean iso-8859-1 cubic-meters.
# Each entry has preamble with the 2-min mean and then detailed (per second) measurements.

echo 'Sample #,Start Date,Start Time,Mean' > "${file_to_process}.temp1"
cat "${file_to_process}" |  iconv -f iso-8859-1 | awk 'BEGIN { FS=","; LINE=""; } /^Sample #/ { print LINE; LINE=$2 } /^Start Date/ { LINE = LINE "," $2 } /^Start Time/ { LINE = LINE "," $2 } /^Mean/ { LINE = LINE "," $2 }' | tail +2 >> "${file_to_process}.temp1"

# args: infile, outfile, separator,
# date_col, time_col, datetime_fmt, instrument_tz,
# measurement_col, index_col

# If there is single datetime column, give date_col==time_col.
# The datetime_fmt should assume date_col + " " + time_col.
# The index_col will be dropped. Give "no_index" to not drop any column.

python3 ${BINDIR}/uf_csv.py "${file_to_process}.temp1" "${file_to_store}.csv" ',' 'Start Date' 'Start Time' '%m/%d/%y %H:%M:%S' "${instrument_tz}" 'Mean' 'Sample #'

bash ${BINDIR}/uf_valve_finder.sh "${file_to_store}.csv" "${file_to_store}_valve.csv" "${station_name}"

python3 ${BINDIR}/uf_lp_maker.py "${file_to_store}_valve.csv" "${station_name}" "${instrument_name}" > "${file_to_store}.lp"

