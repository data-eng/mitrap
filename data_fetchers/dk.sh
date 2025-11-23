#!/bin/bash

NOWDATE=$(date "+%Y-%m-%d")
URL="https://envs2.au.dk/luftdata_hist/api/api/Air/Aarhus/${NOWDATE}/${NOWDATE}/AARH3"

TMP=$(mktemp)
curl ${URL} -s -o ${TMP}
MYDATE=$(date "+%Y-%m-%d %H:%M:%S")
MYTIMESTAMP=$(date -d "$MYDATE" +%s)
MYFILE=$(date -d "$MYDATE" "+%Y%m%d")

mv ${TMP} /mnt/web/dk/raw/${MYTIMESTAMP}.json

exit 0

