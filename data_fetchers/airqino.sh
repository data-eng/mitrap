#!/bin/bash

source ${HOME}/.influx.env

# The results returned are two hours old, so if we only asked for today
# we would miss the last two hours of each day
DATE1=$(date --date="yesterday" +%Y-%m-%d)
DATE2=$(date "+%Y-%m-%d")
MYTIMESTAMP=$(date +%s)

TOKEN=$(curl --location 'https://airqino-auth.magentalab.it/realms/airqino/protocol/openid-connect/token' --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=refresh_token' --data-urlencode 'client_id=airqino-api' --data-urlencode "client_secret=${AIRQINO_CLIENT_SECRET}" --data-urlencode "refresh_token=${AIRQINO_REFRESH_TOKEN}" 2>/dev/null  | jq -r .access_token)

curl --location "https://airqino-api.magentalab.it/getHourlyAvg/${AIRQINO_STATION}/${DATE1}/${DATE2}" --header "Authorization: Bearer ${TOKEN}" -s -o "/mnt/web/airqino/raw/${AIRQINO_STATION}-${MYTIMESTAMP}.txt" 

curl --location "https://airqino-api.magentalab.it/getHourlyAvg/SMART802/${DATE1}/${DATE2}" --header "Authorization: Bearer ${TOKEN}" -s -o "/mnt/web/airqino/raw/SMART802-${MYTIMESTAMP}.txt" 

