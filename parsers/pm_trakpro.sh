#!/bin/bash

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

echo "ENV pm_trakpro: $BINDIR $instrument_tz"

# args: infile, outfile, separator,
# date_col, time_col, datetime_fmt, instrument_tz,
# measurement_col, index_col

# There is a preamble at every re-start, sometimes in the middle of the file.
# Better filter out all non-data lines and manually inject the header.
# Also, the sep is a number of spaces, aimed at visual alignment.

echo "Date,Time,pm1,pm25,resp,pm10,total,station_name,instrument_name" > "${file_to_store}_temp1"

cat "${file_to_process}" | sed 's|[[:space:]][[:space:]]*|,|g' | sed 's|,$||' |\
	grep '^[0-9][0-9]/[0-9][0-9]/202[6-9],[0-2][0-9]:[0-5][0-9]:[0-5][0-9],[0-9][0-9.]*,' |\
	sed "s|$|,${station_name},${instrument_name}|" >> "${file_to_store}_temp1"

python3 ${BINDIR}/date_formatter.py "${file_to_store}_temp1" "${file_to_store}.csv" 'Date' 'Time' '%m/%d/%Y %H:%M:%S' "${instrument_tz}"

python3 ${BINDIR}/pm_lp_maker.py "${file_to_store}.csv" > "${file_to_store}.lp"

