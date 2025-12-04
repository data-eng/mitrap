#!/bin/bash

BINDIR="/home/debian/live"
BINDIR=/mnt/mitrap/mitrap.git

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
station_name=$3
instrument_name=$4

if [[ "x${file_to_process}" =~ exportLevel1.*txt ]]; then
    # 23-line preamble
    cat ${file_to_process} | tail +24 > ${file_to_process}.temp1
    python3 ${BINDIR}/parsers/mpss_csv.py "${file_to_process}.temp1" "${file_to_process}.temp2" "${station_name}" "${instrument_name}"

elif [[ "x${file_to_process}" =~ .inv$ ]]; then
    bash ${BINDIR}/parsers/mpss_inv.sh "${file_to_process}" "${file_to_process}.temp2" "${station_name}" "${instrument_name}"

else
    echo "Unknown file type: ${file_to_process}"
    exit 1
fi

#bash ${BINDIR}/parsers/valve_finder.sh "${file_to_process}.temp2" "${file_to_process}.temp3"
cp "${file_to_process}.temp2" "${file_to_process}.temp3"

#python3 ${BINDIR}/parsers/mpss_calc.py "${file_to_process}.temp3" "${file_to_store}.csv"
cp "${file_to_process}.temp3" "${file_to_store}.csv"

python3 ${BINDIR}/parsers/mpss_lp_maker.py "${file_to_store}.csv" > "${file_to_store}.lp"
