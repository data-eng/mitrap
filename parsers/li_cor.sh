#!/bin/bash

shopt -s lastpipe

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

BINDIR=~/src/mitrap.git # /home/debian/live

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$installation_name")
instrument_name=$(escape_tag_value "$instrument_name")

current_date=""
previous_hour=0

# The first line is the date, the second line is the header

cat "$file_to_process" | head -1 | while IFS= read -r line; do
    # first line - date string
    if [[ "$line" =~ ^\"([0-9]{4}-[0-9]{2}-[0-9]{2})\ at\ ([0-9]{2}): ]]; then
        current_date="${BASH_REMATCH[1]}"
        previous_hour="${BASH_REMATCH[2]}"
    else
	echo "Error parsing date"
	exit 1
    fi
done

echo "Date $(cat "$file_to_process" | head -2 | tail +2 )" > "${file_to_process}.temp"

cat "$file_to_process" | tail +3 | while IFS= read -r line; do
    echo "${current_date} ${line}"
done >> "${file_to_process}.temp"

python3 ${BINDIR}/parsers/li_cor.py ${file_to_process}.temp ${file_to_store}.csv

# Make the influx line with CO2 value only
cat ${file_to_store}.csv | tail +2 | cut -d ',' -f 1,3 | (while IFS=',' read -r timestamp_unix co2; do
  write_query="co2,installation=${installation_name},instrument=${instrument_name} co2=${co2} ${timestamp_unix}"
  echo $write_query >> "${file_to_store}.lp"
done)

exit 0
