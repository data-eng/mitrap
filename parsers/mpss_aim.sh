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

echo "mpss ${instrument_name} ENV: $BINDIR $instrument_tz"


if [[ "${instrument_name}" == "SMPS" ]]; then

    # iconv to clean iso-8859-1 cubic-meters.
    # Remove the preamble.
    cat "${file_to_process}" | tail +26 | iconv -f iso-8859-1 |\
	tr '\t' ',' |\
	cut -d, -f 1-130 > "${file_to_store}_temp1"

    # Set the uf_csv arguments
    DATE_COL='Date'
    TIME_COL='Start Time'
    DATETIME_FMT='%d/%m/%Y %H:%M:%S'

else
    echo "Bad instrument name ${instrument_name}"
    exit 1
fi

python3 ${BINDIR}/mpss_aim.py "${file_to_store}_temp1" "${file_to_store}_temp2.csv" "${DATE_COL}" "${TIME_COL}" "${DATETIME_FMT}" "${station_name}" "${instrument_name}" "${instrument_tz}" > "${file_to_store}.lp"


