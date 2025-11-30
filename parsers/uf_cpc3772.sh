#!/bin/bash

BINDIR="/home/debian/live"

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

# iconv to clean iso-8859-1 cubic-meters.
# Each entry has its own header (starting with "Sample #") followed by
# one line with the actual values.
# The AWK scripts the first header only and checks that all
# subsequent headers are the same

cat "${file_to_process}" |  iconv -f iso-8859-1 | awk 'BEGIN { N=0; H=""; NUMFIELDS=0; FS="," } N==1 { N=0; if (NUMFIELDS==NF) { print } else { print "ERROR: Line " NR " wanted " NUMFIELDS " found " NF " values" } } /^Sample #,Start Date,/ { if (H=="") { N=1; H=$0; NUMFIELDS=NF; print } else if (H==$0) { N=1 } else { print "ERROR: Line " NR " wanted " NUMFIELDS " found " NF " headers" } }' > ${file_to_process}.temp1

# Log the errors
cat "${file_to_process}.temp1" | grep ^ERROR

cat "${file_to_process}.temp1" | grep -v ^ERROR > "${file_to_process}.temp2"

python3 ${BINDIR}/parsers/uf_cpc3772.py "${file_to_process}.temp2" "${file_to_store}.csv" "${installation_name}" "${instrument_name}" "UTC" > /dev/null

bash ${BINDIR}/parsers/uf_valve_finder.sh "${file_to_store}.csv" "${file_to_store}_valve.csv"

python3 ${BINDIR}/parsers/uf_cpc3772_lp.py "${file_to_store}_valve.csv" "${installation_name}" "${instrument_name}" > "${file_to_store}.lp"

