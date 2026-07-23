#!/bin/bash

file_to_process=$1
file_to_store=$2
station_name=$3
instrument_name=$4
instrument_tz=$5

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV org_csv: $BINDIR $instrument_tz"

python3 ${BINDIR}/date_formatter.py "${file_to_process}" "${file_to_store}_temp1" 'Year' 'Stop_DOY' 'decimal' "${instrument_tz}"

python3 ${BINDIR}/org_csv.py "${file_to_store}_temp1" "${station_name}" "${instrument_name}" "${file_to_store}.csv" "${instrument_tz}" > "${file_to_store}.lp"

