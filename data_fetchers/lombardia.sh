#!/bin/bash

export YY=$(date "+%Y")
export MM=$(date "+%m")
export DD=$(date "+%d")
export HH=$(date "+%H")

Q='{
  "query": "SELECT * WHERE date_extract_y(data) == 2026 AND date_extract_m(data) == @MM@ AND date_extract_d(data) == @DD@ AND date_extract_hh(data) == @HH@ AND idsensore IN (@SENSORS@)",
  "page": {
    "pageNumber": 1,
    "pageSize": 10
  },
  "includeSynthetic": false
}'

SENSORS="'5504','5551','5827','5834','5834','6328','6354'"

QQ=$(echo "$Q" | sed s/@YY@/${YY}/ | sed s/@MM@/${MM}/ | sed s/@DD@/${DD}/ | sed s/@HH@/${HH}/ | sed s/@SENSORS@/${SENSORS}/)

MYTIMESTAMP=$(date +%s)

echo "$QQ" > "/mnt/web/lombardia/raw/${MYTIMESTAMP}.query" 

curl --header 'X-App-Token: wVdkA95U2ZtPTmAcwJz5OYNg1' --json "$QQ" https://www.dati.lombardia.it/api/v3/views/nicp-bhqi/query.json -s -o "/mnt/web/lombardia/raw/${MYTIMESTAMP}.json"

exit 0

