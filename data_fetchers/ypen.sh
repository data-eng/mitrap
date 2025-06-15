#!/bin/bash

URL='http://84.205.254.113/getdata.aspx'
STATIONS='1 2 7'

TMP=$(mktemp)
curl ${URL} -s -o ${TMP}

for STATION_ID in ${STATIONS}; do
    # Sometimes there is something wrong with a station.
    # Then the entire row for this station is missing
    DATETIME=$(xmlstarlet sel -t -v "xml/rs:data/z:row[@station_id=${STATION_ID}]/@datetime" ${TMP})
    if [[ x${DATETIME} != x ]]; then
	# Careful: server TZ must be the same as sensor TZ
	TIMESTAMP=$(date -d "${DATETIME}" +%s)
	# Turn into ns, the default precision in influx
	TIMESTAMP="${TIMESTAMP}000000"
	NOX=$(xmlstarlet sel -t -v "xml/rs:data/z:row[@station_id=${STATION_ID}]/@NOx" ${TMP})
	NO2=$(xmlstarlet sel -t -v "xml/rs:data/z:row[@station_id=${STATION_ID}]/@NO2" ${TMP})
	CO=$(xmlstarlet sel -t -v "xml/rs:data/z:row[@station_id=${STATION_ID}]/@CO" ${TMP})
	echo "govatmo,station=${STATION_ID} NOX=${NOX},NO2=${NO2},CO=${CO} ${TIMESTAMP}"
    fi
done

rm -f ${TMP}

exit 0
