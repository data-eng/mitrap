#!/bin/bash

shopt -s lastpipe

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

if [[ x"$5" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

SPOOL=/mnt/spool

file_to_process=$1
file_to_store=$2
station_name=$3
instrument_name=$4
instrument_tz=$5

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV co2_licor: $BINDIR $instrument_tz"


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
	echo "LICOR, new: num_days: 0, header_date: ${header_date}"
    else
	# File fraction. Use whole file, read the spool.
	# Warn and fall back if no spool was found.
	cp -p "$file_to_process" "${file_to_process}.temp"
	if [[ -f "${SPOOL}/licor_${installation_name}" ]]; then
	    cat "${SPOOL}/licor_${installation_name}" | read -r num_days header_date header_hour
	    echo "LICOR, spool: num_days: ${num_days}, header_date: ${header_date}"
	else
	    echo "WARNING: Reading file fraction but missing spoolfile ${SPOOL}/licor_${installation_name}"
	    echo "WARNING: Falling back to today's date"
	    header_date=$(date --iso)
	    header_hour="00:01"
	    num_days=0
	    echo "LICOR, fallback: num_days: ${num_days}, header_date: ${header_date}"
	fi
    fi
done

python3 ${BINDIR}/co2_licor.py "${file_to_process}.temp" "${header_date}" "${header_hour}" "${num_days}" "${file_to_store}.csv"
num_days=$?

# Update the spool
echo "${num_days} ${header_date} ${header_hour}" > "${SPOOL}/licor_${installation_name}"
echo "LICOR, update: num_days: ${num_days}, header_date: ${header_date}"

# Make the influx line with CO2 value only
python3 ${BINDIR}/co2.py "${file_to_store}.csv" "${installation_name}" "${instrument_name}" "${instrument_tz}" '%Y-%m-%d %H:%M:%S' > "${file_to_store}.lp"

exit 0

