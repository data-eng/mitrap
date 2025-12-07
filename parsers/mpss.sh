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

echo "ENV ae31: $BINDIR $instrument_tz"


if [[ "x${file_to_process}" =~ exportLevel1.*txt ]]; then
    # 23-line preamble
    cat ${file_to_process} | tail +24 > ${file_to_process}.temp1
    python3 ${BINDIR}/mpss_csv.py "${file_to_process}.temp1" "${file_to_process}.temp2" "${station_name}" "${instrument_name}"

elif [[ "x${file_to_process}" =~ .inv$ ]]; then
    bash ${BINDIR}/mpss_inv.sh "${file_to_process}" "${file_to_process}.temp2" "${station_name}" "${instrument_name}"

else
    echo "Unknown file type: ${file_to_process}"
    exit 1
fi

#bash ${BINDIR}/valve_finder.sh "${file_to_process}.temp2" "${file_to_process}.temp3"
cp "${file_to_process}.temp2" "${file_to_process}.temp3"

#python3 ${BINDIR}/mpss_calc.py "${file_to_process}.temp3" "${file_to_store}.csv"
cp "${file_to_process}.temp3" "${file_to_store}.csv"

python3 ${BINDIR}/mpss_lp_maker.py "${file_to_store}.csv" > "${file_to_store}.lp"

