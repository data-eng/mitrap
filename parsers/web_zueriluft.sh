#!/bin/bash

if [[ x"$2" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "web_zueriluft ENV: $BINDIR $instrument_tz"

echo "station,variable,datetime_start,datetime,value,unit,error" > "${file_to_store}_temp1"

cat "${file_to_process}" | iconv -f iso-8859-1 |\
       	grep ';NO.;' | sed 's/NO/no/' |\
	sed 's|\r$||' | sed 's/;$//' | tr ';' ',' |\
	sed 's/^Zch_Schimmelstrasse/Zurich - Schimmelstrasse - CE/' |\
	sed 's/^Zch_Rosengartenstrasse/Zurich - Rosengartenstrasse - CE/' >> "${file_to_store}_temp1"

python3 ${BINDIR}/web_zueriluft.py "${file_to_store}_temp1" "${file_to_store}" > "${file_to_store}.lp"

