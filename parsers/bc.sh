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

echo "uf ${instrument_name} ENV: $BINDIR $instrument_tz"

if [[ "${instrument_name}" == "MA 200" ]]; then

	echo "date time serial_number datum_id session_id data_format_version firmware_version date_utc timezone_offset gps_lat gps_long gps_speed timebase status battery_remaining accel_x accel_y accel_z tape_position flow_setpoint flow_total flow1 flow2 sample_temp sample_rh sample_dewpoint internal_pressure internal_temp optical_config uv_sen1 uv_sen2 uv_ref uvatn1 uv_atn2 uv_k blue_sen1 blue_sen2 blue_ref blueatn1 blue_atn2 blue_k green_sen1 green_sen2 green_ref greenatn1 green_atn2 green_k red_sen1 red_sen2 red_ref redatn1 red_atn2 red_k ir_sen1 ir_sen2 ir_ref iratn1 ir_atn2 ir_k uv_bc1 uv_bc2 uvbcc blue_bc1 blue_bc2 bluebcc green_bc1 green_bc2 greenbcc red_bc1 red_bc2 redbcc ir_bc1 ir_bc2 irbcc uv_bc1_smooth uv_bcc_smooth blue_bc1_smooth blue_bcc_smooth ir_bc1_smooth ir_bcc_smooth cref aae_wb aae_ff bcc_wb bcc_ff aae bb delta_c pump_drive reporting_temp reporting_pressure wifi_rssi cksum" | tr ' ' ',' > "${file_to_store}_temp1"

	# Many files have error or status lines with date,time,message
	# Filter these out. Use grep -a to not drop the complete file
	# when it appears as binary (has garbage lines).
	cat "${file_to_process}" | grep -a ',.*,.*,' >> "${file_to_store}_temp1"

	SEP=','
	DATE_COL='date_utc'
	TIME_COL='date_utc'
	DATETIME_FMT='%Y-%m-%dT%H:%M:%S'
	MEAS_COL='irbcc'
	# Unit conversion, where needed.
	# The values in the file will be multiplied by the number given here.
	MEAS_UNIT='1E-3'

elif [[ "${instrument_name}" == "AE33" ]]; then

	# Some lines have as time '.000000E+1'
	# Good times look like: 
	#  20260615T183306.0+0200
	#  Chop off the .0+0200 at the end.
	cat "${file_to_process}" | grep -v '^.00000' | sed 's/^\(........T......\).0.0200,/\1,/' > "${file_to_store}_temp1" 

	SEP=','
	DATE_COL='Time'
	TIME_COL='Time'
	DATETIME_FMT='%Y%m%dT%H%M%S'
	MEAS_COL='AE33BC6'
	MEAS_UNIT='1E-3'
	RESAMPLE=1

	# TODO: Some files do not have MEAS_COL. Ignore.
	# For this installation, all Measurement_NoRun_S0002_*
	# seem to be good and all Measurement_NoRun_S0001_*
	# seem to be bad.

else
	echo "Bad instrument name ${instrument_name}"
	exit 1
fi


# If there is single datetime column, give date_col==time_col.
# The datetime_fmt should assume date_col + " " + time_col.
 
echo python3 ${BINDIR}/bc.py "${file_to_store}_temp1" "${file_to_store}_temp2" "${SEP}" "${DATE_COL}" "${TIME_COL}" "${DATETIME_FMT}" "${instrument_tz}" "${MEAS_COL}" "${MEAS_UNIT}"
python3 ${BINDIR}/bc.py "${file_to_store}_temp1" "${file_to_store}_temp2" "${SEP}" "${DATE_COL}" "${TIME_COL}" "${DATETIME_FMT}" "${instrument_tz}" "${MEAS_COL}" "${MEAS_UNIT}"

if [[ x"${RESAMPLE}" == x1 ]]; then
	# Some instruments give 1-sec data. Resample to 1min
	python3 ${BINDIR}/resample.py "${file_to_store}_temp2" "${file_to_store}_temp3"
	grep -v 'concentration_cc=nan' "${file_to_store}_temp3" > "${file_to_store}_temp4"
else
	mv "${file_to_store}_temp2" "${file_to_store}_temp4"
fi

bash ${BINDIR}/valve_finder.sh "${file_to_store}_temp4" "${file_to_store}.csv" "${station_name}" "${bucket_name}"

python3 ${BINDIR}/bc_lp_maker.py "${file_to_store}.csv" "${station_name}" "${instrument_name}" | grep -v 'concentration_cc=nan' > "${file_to_store}.lp"

