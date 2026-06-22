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
bucket_name=$6

if [[ x${bucket_name} == x ]]; then
	bucket_name='mitrap006'
fi

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "inorg ${instrument_name} ENV: $BINDIR $instrument_tz"

cat "${file_to_process}" | gawk '\
	BEGIN { FS=","; }
	/^Start of EC1/ { split($2,datetime," ");
                          split(datetime[1],date,"-");
			  datetimestr="20" date[3] "-" date[1] "-" date[2] " " datetime[2]; }
	/^Fe,26,/ { fe26=$5; }
	/^K ,19,/ { k19=$5; }
	/^S ,16,/ { s16=$5; }
	/^Cu,29,/ { cu29=$5; }
	/Sample Type =/ { sample_type=$3; cal=sample_type-1 }
	END { print "calibration=" cal " S16=" s16 ",K19=" k19 ",Fe26=" fe26 ",Cu29=" cu29 " " datetimestr }' > "${file_to_store}_temp"

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}
stn=$(escape_tag_value "$station_name")
ins=$(escape_tag_value "$instrument_name")

cat "${file_to_store}_temp" | while read CAL MEAS DATE TIME ; do tssec=$(TZ="${instrument_tz}" date +'%s' -d "${DATE} ${TIME}") ; echo "inorg,installation=${stn},instrument=${ins},${CAL} ${MEAS} ${tssec}000000000" ; done > "${file_to_store}.lp"

