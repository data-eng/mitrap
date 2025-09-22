#!/bin/bash

BINDIR="/home/debian/live"

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

# /mnt/incoming/mitrap000/OPS/*.csv

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$installation_name")
instrument_name=$(escape_tag_value "$instrument_name")

declare -a headers
DATA_SECTION=false

# Function to trim whitespace
trim() {
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

sed_insta_name=$(echo ${installation_name} | sed 's|\\|\\\\|g' )
sed_instr_name=$(echo ${instrument_name} | sed 's|\\|\\\\|g' )

cat "$file_to_process" | tail +16 | cut -d ',' -f 2,3,18-33 |\
sed 's|\([0-9][0-9]\)/\([0-9][0-9]\)/\([0-9][0-9][0-9][0-9]\),\([0-9:]*\),|\3-\1-\2 \4,'"${sed_insta_name}"','"${sed_instr_name}"',|' > "${file_to_process}.temp"


# Perform the PM2.5 calculation and write out the CSV
python3 ${BINDIR}/parsers/pm25.py ${file_to_process}.temp ${file_to_store}.csv

# Make the influx line with PM2.5 value only
cat ${file_to_store}.csv | tail +2 | cut -d ',' -f 1,4 | (while IFS=',' read -r datetime pm25; do
  timestamp_unix=$(date -d "${datetime}" +%s%N)
  write_query="grimm,installation=${installation_name},instrument=${instrument_name} pm25=${pm25} ${timestamp_unix}"
  echo $write_query >> "${file_to_store}.lp"
done)
