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

echo "uf ${instrument_name} ENV: $BINDIR $instrument_tz"

if [[ "${instrument_name}" == "CPC 3010" ]]; then

	# iconv to clean iso-8859-1 cubic-meters.
	# Each entry has preamble with the 2-min mean and then detailed (per second) measurements.
	echo 'Sample #,Start Date,Start Time,Mean' > "${file_to_store}_temp1"
	cat "${file_to_process}" |  iconv -f iso-8859-1 | awk 'BEGIN { FS=","; LINE=""; } /^Sample #/ { print LINE; LINE=$2 } /^Start Date/ { LINE = LINE "," $2 } /^Start Time/ { LINE = LINE "," $2 } /^Mean/ { LINE = LINE "," $2 }' | tail +2 >> "${file_to_store}_temp1"

	# Set the uf_csv arguments
	SEP=','
	DATE_COL='Start Date'
	TIME_COL='Start Time'
	DATETIME_FMT='%m/%d/%y %H:%M:%S'
	MEAS_COL='Mean'
	INDEX_COL='Sample #'

elif [[ "${instrument_name}" == "CPC 3330" ]]; then

	# iconv to clean iso-8859-1 cubic-meters.
	# Remove the preamble.
	cat "${file_to_process}" | tail +15 | iconv -f iso-8859-1 > "${file_to_store}_temp1"

	# Set the uf_csv arguments
	SEP=','
	DATE_COL='Date'
	TIME_COL='Start Time'
	DATETIME_FMT='%m/%d/%Y %H:%M:%S'
	MEAS_COL='Total Conc. (#/cm³)'
	INDEX_COL='Sample #'

elif [[ "${instrument_name}" == "CPC 3750" ]]; then

	cp "${file_to_process}" "${file_to_store}_temp1"

	# Set the uf_csv arguments
	SEP=' '
	DATE_COL='#date'
	TIME_COL='time'
	DATETIME_FMT='%Y-%m-%d %H:%M:%S'
	MEAS_COL='concentration[#/cm3]'
	INDEX_COL='no_index'

elif [[ "${instrument_name}" == "CPC 3752" ]]; then

	# Remove the preamble.
	cat "${file_to_process}" | tail +21 > "${file_to_store}_temp1"

	HEADER=$(cat "${file_to_process}.temp" | head -1)

	if [[ "${HEADER}" == "Date-Time,Elapsed Time(m),Concentration (#/cm3),Counts,Dilution Factor,Aerosol Humidity (%),Aerosol Temperature (°C),Error," ]]; then
		# Set the uf_csv arguments
		SEP=','
		DATE_COL='Date-Time'
		TIME_COL='Date-Time'
		DATETIME_FMT='%Y-%m-%d %H:%M:%S'
		MEAS_COL='Concentration (#/cm3)'
		INDEX_COL='no_index'
	else
		echo "Bad file ${file_to_process}"
		exit 1
	fi

elif [[ "${instrument_name}" == "CPC 3773" ]]; then

	# iconv to clean iso-8859-1 cubic-meters.
	# Each entry has its own header (starting with "Sample #") followed by
	# one line with the actual values.
	# The AWK scripts the first header only and checks that all
	# subsequent headers are the same
	cat "${file_to_process}" |  iconv -f iso-8859-1 |\
		awk 'BEGIN { N=0; H=""; NUMFIELDS=0; FS="," } N==1 { N=0; if (NUMFIELDS==NF) { print } else { print "ERROR: Line " NR " wanted " NUMFIELDS " found " NF " values" } } /^Sample #,Start Date,/ { if (H=="") { N=1; H=$0; NUMFIELDS=NF; print } else if (H==$0) { N=1 } else { print "ERROR: Line " NR " wanted " NUMFIELDS " found " NF " headers" } }' > "${file_to_store}_temp1"

	# Log the errors
	cat "${file_to_store}_temp1" | grep ^ERROR
	# Make a clean temp1
	cat "${file_to_store}_temp1" | grep -v ^ERROR > "${file_to_store}_temp2"
	mv "${file_to_store}_temp2" "${file_to_store}_temp1"

	# Set the uf_csv arguments
	SEP=','
	DATE_COL='Start Date'
	TIME_COL='Start Time'
	DATETIME_FMT='%m/%d/%y %H:%M:%S'
	MEAS_COL='Conc Mean'
	INDEX_COL='Sample #'

else
	echo "Bad instrument name ${instrument_name}"
	exit 1
fi


# If there is single datetime column, give date_col==time_col.
# The datetime_fmt should assume date_col + " " + time_col.
# The index_col will be dropped. Give "no_index" to not drop any column.

python3 ${BINDIR}/uf_csv.py "${file_to_store}_temp1" "${file_to_store}_temp1.csv" "${SEP}" "${DATE_COL}" "${TIME_COL}" "${DATETIME_FMT}" "${instrument_tz}" "${MEAS_COL}" "${INDEX_COL}"

bash ${BINDIR}/valve_finder.sh "${file_to_store}_temp1.csv" "${file_to_store}.csv" "${station_name}"

python3 ${BINDIR}/uf_lp_maker.py "${file_to_store}.csv" "${station_name}" "${instrument_name}" > "${file_to_store}.lp"

