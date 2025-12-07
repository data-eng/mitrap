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

instrument_tz="UTC"

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV pm_raw: $BINDIR $instrument_tz"

# args: infile, outfile, separator,
# date_col, time_col, datetime_fmt, instrument_tz,
# measurement_col, index_col

# If there is single datetime column, give date_col==time_col.
# The datetime_fmt should assume date_col + " " + time_col.
# The index_col will be dropped. Give "no_index" to not drop any column.

python3 ${BINDIR}/raw.py "${file_to_process}" "${file_to_process}".temp1 "${station_name}" "${instrument_name}" "${instrument_tz}"

python3 ${BINDIR}/pm_lp_maker.py "${file_to_process}".temp1 > "${file_to_store}.lp"

