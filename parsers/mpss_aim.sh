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

echo "mpss ${instrument_name} ENV: $BINDIR $instrument_tz"

# clean iso-8859-1 cubic-meters.
cat "${file_to_process}" | iconv -f iso-8859-1 > "${file_to_store}_temp1"

# There is a preamble with varying length before the header
# Find the header, and also find if it gives date-time or
# timestamp from beginning of year

HEADER_LINE=$(cat ${file_to_store}_temp1 | grep -ni '^start date.*end date.*start year*.end year' | sed 's|^\([0-9][0-9]*\):.*$|\1|')
if [[ x${HEADER_LINE} == x ]]; then
	HEADER_LINE=$(cat ${file_to_store}_temp1 | grep -ni '^sample #.*date.*start time' | sed 's|^\([0-9][0-9]*\):.*$|\1|')
	if [[ x${HEADER_LINE} == x ]]; then
		echo "BAD FILE"
		exit 1
	fi
    	DATE_COL='Date'
	TIME_COL='Start Time'
    	DATETIME_FMT='%d/%m/%Y %H:%M:%S'
else
	# in decimal time, the DATE_COL is the starting point
	# and the TIME_COL is the decimal increment, in days
    	DATE_COL='End Year'
	TIME_COL='End Date'
    	DATETIME_FMT='decimal'
fi

#echo $DATETIME
#echo $HEADER_LINE

# Remove the preamble.
# Some lines have '-1.#IO' some metadata columns, Density (g/cm³) and other.
# These lines are bad data anyway, and also make pandas.read_csv() complain
# about mixed types.

cat "${file_to_store}_temp1" | tail +${HEADER_LINE} | tr '\t' ',' |\
    grep -v ',-1.#IO' > "${file_to_store}_temp2"

# Check that all rows have the same number of columns
COLS_HEADER=$(cat ${file_to_store}_temp2 | head -1 | gawk 'BEGIN{FS=","}{print NF}')
COLS_MATCH=$(cat ${file_to_store}_temp2 | gawk 'BEGIN{FS=","}{print NF}' | uniq | wc -l)
if [[ ${COLS_MATCH} != 1 ]]; then
	echo "BAD FILE: not all rows have the same columns"
	exit 1
fi


# Parse decimal date format into datetime

python3 ${BINDIR}/date_formatter.py "${file_to_store}_temp2" "${file_to_store}_temp3" 'End Year' 'End Date' decimal "${instrument_tz}"

python3 ${BINDIR}/mpss_aim.py "${file_to_store}_temp3" "${file_to_store}_temp4" "${station_name}" "${instrument_name}" hoekvanholland

bash ${BINDIR}/valve_finder.sh "${file_to_store}_temp4" "${file_to_store}.csv" "${station_name}" "${bucket_name}"

python3 ${BINDIR}/mpss_interpolate.py "${file_to_store}.csv" "${file_to_store}_i20.csv" 24
python3 ${BINDIR}/mpss_interpolate.py "${file_to_store}.csv" "${file_to_store}_i32.csv" 32
python3 ${BINDIR}/mpss_interpolate.py "${file_to_store}.csv" "${file_to_store}_006.csv" mitrap006

python3 ${BINDIR}/mpss_lp_maker.py "${file_to_store}_i32.csv" > "${file_to_store}.lp"

