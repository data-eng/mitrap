#!/bin/bash

CONFIG=$1
DATADIR=$2
PKGDIR=$3

if [[ x"$3" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

temp=$(realpath "$0") && temp=$(dirname "${temp}")
BINDIR=${temp}/..
PROCDIR=${BINDIR}/parsers/


# Read in installations config

declare -A toml
shopt -s lastpipe

cat ${CONFIG} | ${BINDIR}/toml2bash | while read KEY VALUE; do
    toml["$KEY"]=$VALUE
done

KEYS="${!toml[@]}"
STATIONS=$(echo ${KEYS} | tr ' ' '\n' | sed 's/\..*$//' | sort | uniq)


for STATION in ${STATIONS}; do
    mykey="${STATION}.city"
    STATION_NAME="${toml[$mykey]}"
    mykey="${STATION}.tz"
    STATION_TZ="${toml[$mykey]}"
    mykey="${STATION}.start"
    STATION_START="${toml[$mykey]}"
    mykey="${STATION}.end"
    STATION_END="${toml[$mykey]}"
    mykey="${STATION}.bucket"
    STATION_BUCKET="${toml[$mykey]}"

    STATION_DIR="${PKGDIR}/${STATION}"
    mkdir -p ${STATION_DIR}

    echo "===== STATION ${STATION} ${STATION_NAME} FROM ${STATION_START} TO ${STATION_END} WRITE AT ${STATION_BUCKET}"
    # Find all sub-keys under $STATION that have sub-sub-keys (have a dot)
    # The level under $STATION is the name of the processor
    # The next level must have 'name', 'file', ... third-levels.
    TYPES=$(echo $KEYS | tr ' ' '\n' | grep $STATION | sed "s/^$STATION\.//" | grep -F '.' | sed 's/\..*$//' | sort | uniq) 
    echo "TYPES: $TYPES"

    # Priority types must come first
    TYPES0=""
    TYPES1=""
    for TYPE in $TYPES; do
	FIELDS=$(echo $KEYS | tr ' ' '\n' | grep "^${STATION}.${TYPE}" | sed "s/^${STATION}.${TYPE}.//" | sort | tr '\n' '_')
	mykey="${STATION}.${TYPE}.pri"
	if [[ ${toml[$mykey]} == 0 ]]; then
	   TYPES0="$TYPES0 $TYPE"
   	else
	   TYPES1="$TYPES1 $TYPE"
	fi	
    done
    TYPES="$TYPES0 $TYPES1"
    echo "Prioritized TYPES: $TYPES"

    for TYPE in $TYPES; do
	FIELDS=$(echo $KEYS | tr ' ' '\n' | grep "^${STATION}.${TYPE}" | sed "s/^${STATION}.${TYPE}.//" | tr '\n' '_')
	# TZ, START, END are optional and default to STATION_{TZ,START,END}
	if [[ "${FIELDS}" =~ "tz_" ]]; then
	    mykey="${STATION}.${TYPE}.tz"
	    INSTRUMENT_TZ="${toml[$mykey]}"
	else
	    INSTRUMENT_TZ="${STATION_TZ}"
	fi
	if [[ "${FIELDS}" =~ "start_" ]]; then
	    mykey="${STATION}.${TYPE}.start"
	    INSTRUMENT_START="${toml[$mykey]}"
	else
	    INSTRUMENT_START="${STATION_START}"
	fi
	if [[ "${FIELDS}" =~ "end_" ]]; then
	    mykey="${STATION}.${TYPE}.end"
	    INSTRUMENT_END="${toml[$mykey]}"
	else
	    INSTRUMENT_END="${STATION_END}"
	fi


	mykey="${STATION}.${TYPE}.name"
	INSTRUMENT=${toml[$mykey]}
	mykey="${STATION}.${TYPE}.file"

	# Start and end timestamps, interpreting the end date as included,
	# at the station's timezone regardless of the instrument's TZ setting.
	start_ts=$(TZ="${STATION_TZ}" date -d "${INSTRUMENT_START}T00:00:00" +%s%N)
	end_ts=$(TZ="${STATION_TZ}" date -d "${INSTRUMENT_END}T23:59:59.999999999" +%s%N)

	echo "INSTRUMENT ${INSTRUMENT} FILES ${toml[$mykey]} for key $mykey FROM ${INSTRUMENT_START} TO ${INSTRUMENT_END}"
	i=0
	OIFS="$IFS"
	IFS=$'\n'
	for F in $(find ${DATADIR} -type f -wholename "${DATADIR}/${STATION}/${toml[$mykey]}")
	do
	    F=${F#${DATADIR}}
	    echo "Doing file $F"

            INFLUXFILE="${STATION_DIR}/${TYPE}_${i}"
	    ORIG_SUFF=$(echo $F|sed 's|.*\.\([^.]*\)$|\1|')
	    ORIG_FILE="${STATION_DIR}/${TYPE}_${i}_orig.${ORIG_SUFF}"

	    # Remove DOS line terminations, also caring for files with \r only (eg, IGOR files)
	    cat "${DATADIR}/${F}" | sed 's|\r$||' | sed 's|\r|\n|g' > "${ORIG_FILE}"
	    echo "EXEC ${PROCDIR}/${TYPE}.sh ${ORIG_FILE} ${INFLUXFILE} ${STATION_NAME} ${INSTRUMENT} ${INSTRUMENT_TZ}"
	    bash ${PROCDIR}/${TYPE}.sh "${ORIG_FILE}" "${INFLUXFILE}" "${STATION_NAME}" "${INSTRUMENT}" "${INSTRUMENT_TZ}"

	    # Check that the timestamps are within this package's range
	    my_first_ts=$(cat ${INFLUXFILE}.lp | head -1 | sed 's|^.* \([0-9]*\)$|\1|')
	    my_last_ts=$(cat ${INFLUXFILE}.lp | tail -1 | sed 's|^.* \([0-9]*\)$|\1|')
	    if [[ my_first_ts -gt end_ts ]]; then
		echo "$F is out of range"
		rm ${ORIG_FILE}
		rm ${INFLUXFILE}.*
	    elif [[ my_last_ts -lt start_ts ]]; then
		echo "$F is out of range"
		rm ${ORIG_FILE}
		rm ${INFLUXFILE}.*
	    fi
	    # TODO: handle partially overlapping

            # Write Influx lines to DB
	    # Careful: INFLUXFILE is the pathname without the suffix
            if [[ -s "${INFLUXFILE}.lp" ]]; then
                echo "WRITE ${INFLUXFILE}.lp TO INFLUX"
            fi

	    ((i++))
	done
	# Put the IFS back after changing it for the loop over all files
	IFS="$OIFS"
    done
done

exit 0

