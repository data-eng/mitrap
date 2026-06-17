#!/bin/bash

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

echo "ENV mpss_raw: $BINDIR $instrument_tz"

cat "${file_to_process}" | iconv -f iso-8859-7 |\
	sed 's/0.000E+0/0/g' |\
       	sed 's/E+0\t/\t/g' > "${file_to_store}_temp1"



python3 ${BINDIR}/mpss_raw.py "${file_to_store}_temp1" "${file_to_store}_temp2" "${station_name}" "${instrument_name}" "${instrument_tz}" "%d/%m/%Y %H:%M:%S"

bash ${BINDIR}/valve_finder.sh "${file_to_store}_temp2" "${file_to_store}.csv" "${station_name}" "${bucket_name}"

python3 ${BINDIR}/mpss_lp_maker.py "${file_to_store}.csv" mpss nm > "${file_to_store}.lp"

