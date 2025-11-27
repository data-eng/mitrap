#!/bin/bash

NOWDATE=$(date "+%Y-%m-%d")
URL="https://envs2.au.dk/luftdata_hist/api/api/Air/Aarhus/${NOWDATE}/${NOWDATE}/AARH3"

# Gives 'packet filtered'
#ping -c 1 envs2.au.dk >/dev/null
#if [ $? == 1 ]; then
#        echo "envs2.au.dk is unreachable"
#        exit 1
#fi

TMP=$(mktemp)
curl ${URL} -s -o ${TMP}
MYDATE=$(date "+%Y-%m-%d %H:%M:%S")
MYTIMESTAMP=$(date -d "$MYDATE" +%s)
MYFILE=$(date -d "$MYDATE" "+%Y%m%d")

mv ${TMP} /mnt/web/au/raw/${MYTIMESTAMP}.json

exit 0

