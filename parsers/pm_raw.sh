#!/bin/bash

BINDIR="/home/debian/live"

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
station_name=$3
instrument_name=$4

# args: infile, outfile, separator,
# date_col, time_col, datetime_fmt, instrument_tz,
# measurement_col, index_col

# If there is single datetime column, give date_col==time_col.
# The datetime_fmt should assume date_col + " " + time_col.
# The index_col will be dropped. Give "no_index" to not drop any column.

python3 ${BINDIR}/parsers/raw.py "${file_to_process}" "${file_to_process}".temp1 "${station_name}" "${instrument_name}" "UTC"

python3 ${BINDIR}/parsers/pm_lp_maker.py "${file_to_process}".temp1 > "${file_to_store}.lp"

