#!/bin/bash

NOWDATE=$(date "+%Y-%m-%d")
URLBASE="https://envs2.au.dk/luftdata_hist/api/api/Air"
MYTIMESTAMP=$(date +%s)

# Aarhus, all data
ABBREV="AARH3"
URL="${URLBASE}/Aarhus/${NOWDATE}/${NOWDATE}/${ABBREV}"
curl ${URL} -s -o "/mnt/web/au/raw/${MYTIMESTAMP}_${ABBREV}.json"

for ABBREV in "JAGT1" "HCAB" "HVID" "HCØ"; do
    URL="${URLBASE}/Copenhagen/${NOWDATE}/${NOWDATE}/${ABBREV}"
    curl ${URL} -s -o "/mnt/web/au/raw/${MYTIMESTAMP}_${ABBREV}.json"
done

exit 0
