#!/bin/bash

URL='http://84.205.254.113/getdata.aspx'
STATIONS='1 2 9'

TMP=$(mktemp)
curl ${URL} -s -o ${TMP}
MYDATE=$(date "+%Y-%m-%d %H:%M:%S")
MYTIMESTAMP=$(date -d "$MYDATE" +%s)
MYFILE=$(date -d "$MYDATE" "+%Y%m%d")

for STATION_ID in ${STATIONS}; do
    DATETIME=$(xmlstarlet sel -t -v "xml/rs:data/z:row[@station_id=${STATION_ID}]/@datetime" ${TMP})
    # Sometimes there is something wrong with a station.
    # Then the entire row for this station is missing
    if [[ x${DATETIME} != x ]]; then
	NOX=$(xmlstarlet sel -t -v "xml/rs:data/z:row[@station_id=${STATION_ID}]/@NOx" ${TMP})
	NO2=$(xmlstarlet sel -t -v "xml/rs:data/z:row[@station_id=${STATION_ID}]/@NO2" ${TMP})
	CO=$(xmlstarlet sel -t -v "xml/rs:data/z:row[@station_id=${STATION_ID}]/@CO" ${TMP})
	if [[ ! -f /mnt/ypen/${MYFILE}.csv ]]; then
	    echo "datetime,my_timestamp,station,nox,no2,co" >> /mnt/ypen/${MYFILE}.csv
        fi
	echo "${DATETIME},${MYTIMESTAMP},${STATION_ID},${NOX},${NO2},${CO}" >> /mnt/web/ypen/${MYFILE}.csv
    fi
done

mv ${TMP} /mnt/web/ypen/raw/${MYTIMESTAMP}.xml

exit 0
