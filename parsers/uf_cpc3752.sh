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

cat "${file_to_process}" |  tail +21 > "${file_to_process}.temp1

CHECK=$(cat "${file_to_process}.temp" | head -1)

if [[ ! "${CHECK}" == "Date-Time,Elapsed Time(m),Concentration (#/cm3),Counts,Dilution Factor,Aerosol Humidity (%),Aerosol Temperature (°C),Error," ]]; then
	echo "BAD FILE ${file_to_process}"
else
# args: infile, outfile, separator,
# date_col, time_col, datetime_fmt, instrument_tz,
# measurement_col, index_col
# If there is single datetime column, give date_col==time_col.
# The datetime_fmt should assume date_col + " " + time_col.
# The index_col will be dropped. Give no_index to not drop any column.

	python3 ${BINDIR}/parsers/uf_csv.py "${file_to_process}.temp1" "${file_to_store}.csv" ',' 'Date-Time' 'Date-Time' '%Y-%m-%d %H:%M:%S' 'Europe/Amsterdam' 'Concentration (#/cm3)' 'no_index'

done

