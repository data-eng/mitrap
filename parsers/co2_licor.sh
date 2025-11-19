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

BINDIR=/home/debian/live
SPOOL=/mnt/spool

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$installation_name")
instrument_name=$(escape_tag_value "$instrument_name")

# LI-COR files have the startdate/starthour at the top of the file,
# and then roll over to multiple days. To correctly parse file fragments
# we need to spool the number of days previously rolled.

# The first line is the date, the second line is the header

cat "$file_to_process" | head -1 | while IFS= read -r line; do
    # First line - date string
    # This is the beginning of a file, initialze spool
    if [[ "$line" =~ ^\"([0-9]{4}-[0-9]{2}-[0-9]{2})\ at\ ([0-9]{2}): ]]; then
        header_date="${BASH_REMATCH[1]}"
        header_hour="${BASH_REMATCH[2]}"
	num_days=0
	# Drop the line with the date and the CSV header
	cat "$file_to_process" | tail +3 > "${file_to_process}.temp"
    else
	# File fraction. Use whole file, read the spool.
	# Warn and fall back if no spool was found.
	cp -p "$file_to_process" "${file_to_process}.temp"
	if [[ -f "${SPOOL}/licor_${installation_name}" ]]; then
	    cat "${SPOOL}/licor_${installation_name}" | read -r num_days header_date header_hour
	else
	    echo "WARNING: Reading file fraction but missing spoolfile ${SPOOL}/licor_${installation_name}"
	    echo "WARNING: Falling back to today's date"
	    header_date=$(date --iso)
	    header_hour="00:01"
	    num_days=0
	fi
    fi
done

python3 ${BINDIR}/parsers/co2_licor.py "${file_to_process}.temp" "${header_date}" "${header_hour}" "${num_days}" "${file_to_store}.csv"
num_days=$?

# Update the spool
echo "${num_days} ${header_date} ${header_hour}" > "${SPOOL}/licor_${installation_name}"

# Make the influx line with CO2 value only
python3 ${BINDIR}/parsers/co2.py "${file_to_store}.csv" "${installation_name}" ${instrument_name} > "${file_to_store}.lp"

exit 0
