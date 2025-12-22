#!/bin/bash

shopt -s lastpipe

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

TYPE1='^[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9],[0-2][0-9]:[0-5][0-9]:[0-5][0-9],.*,[01],valve$'
# Sample line:
# 2025-05-12,00:00:26,14.54,PSI,100262.7,Pa,100.2698,kPa,752.129,torr,29.6121,inHg,0.989687,atm,1.002839,bar,8.9,%3,28.5,C3,32.9,%5,27.7,C5,0,valve
# Found in Patission HR

TYPE2='^[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9],.*,[01],valve,[0-9][0-9]*,fan$'
# Sample line:
# 2025-11-25 18:06:12, 14.42,PSI,98976.5,Pa,99.4378,kPa,745.855,torr,29.3646,inHg,0.981397,atm,0.990816,bar,67.1,%3,22.9,C3,29.9,%5,26.6,C5,0,valve,0,fan

TYPE3='^[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9] b.nan,PSI,nan,Pa,nan,kPa,nan,torr,nan,inHg,nan,atm,nan,bar,0.0,%3,0.0,C3,0.0,%5,0.0,C5,[01],valve.*$'
# Sample line:
# 2025-12-20 00:01:40 b'nan,PSI,nan,Pa,nan,kPa,nan,torr,nan,inHg,nan,atm,nan,bar,0.0,%3,0.0,C3,0.0,%5,0.0,C5,0,valve\r\n'

TYPE4='^[0-3][0-9]-[A-Z][a-z][a-z]-[12][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9],\(CS\|AMB\)$'
# Sample lines:
# 14-Jul-2025 11:15:00,AMB
# 14-Jul-2025 11:30:00,CS

cat "${file_to_process}" |\
	sed "s@${TYPE1}@1@" | sed "s@${TYPE2}@2@" | sed "s@${TYPE3}@3@" | sed "s@${TYPE4}@4@" |\
	sed 's|^...*$|0|' | sort | uniq -c |\
	sed 's|^[[:space:]]*\([0-9][0-9]*\)[[:space:]][[:space:]]*\([0-9][0-0]*\)[[:space:]]*$|\1 \2|' |\
	sort -rn | head -1 | cut -d ' ' -f 2 | read TYPE

if [[ x$TYPE == x0 ]]; then
	echo "valve: ERROR, unknown file type"
	exit 1
elif [[ x${TYPE} == x1 ]]; then
	RE=$TYPE1
	cat "${file_to_process}" | grep -a "${RE}" > "${file_to_store}_temp1"
elif [[ x${TYPE} == x2 ]]; then
	RE=${TYPE2}
	cat "${file_to_process}" | grep -a "${RE}" > "${file_to_store}_temp1"
elif [[ x${TYPE} == x3 ]]; then
	RE=${TYPE3}
	cat "${file_to_process}" | grep -a "${RE}" | sed 's| b|,|' | sed 's|\\r\\n||' | tr -d \' > "${file_to_store}_temp1"
elif [[ x${TYPE} == x4 ]]; then
	RE=${TYPE4}
	# Tail +2 to remove the header
	cat "${file_to_process}" | tail +2 | grep -a "${RE}" > "${file_to_store}_temp1"
else
	echo "valve: Error"
	exit 1
fi

# Note that the homogenizing of line termionations in the data fetcher can have
# the side effect that newlines are inserted. This does not hurt, but makes them
# count as bad lkineshere.
cat "${file_to_process}" | grep -va "${RE}" | grep -v '^$' | wc -l | read BADLINES

echo "valve: ENV $BINDIR $instrument_tz PARSING as type ${TYPE} with ${BADLINES} bad lines"

# Parse into csv
python3 ${BINDIR}/valve.py "${file_to_store}_temp1" "${file_to_store}_temp2" ${TYPE} "${station_name}" "${instrument_name}" "${instrument_tz}" 

# Calculate valve states that are too close to a valve position change to
# be taken into account. These are marked with "2" instead of 0/1.
python3 ${BINDIR}/valve_state.py "${file_to_store}_temp2" "${file_to_store}.csv" 

# Make lp lines
python3 ${BINDIR}/valve_lp_maker.py "${file_to_store}.csv" > "${file_to_store}.lp"

