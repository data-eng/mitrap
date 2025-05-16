#!/bin/bash

if [[ x"$1" == x || x"$2" == x ]]; then explode; fi

mitrap_station=$1
BUCKET=$2

DIRECTORY="/mnt/incoming/$mitrap_station/sambashare/AE31/mitrap"

files=("$DIRECTORY"/*.csv)

# DO NOT STORE DOUBLE ENTRIES IN THE DB

# Start writing to influx

#TOKEN=TBD
ORG="mitrap"

for file in "${files[@]}"; do

  while IFS=',' read -r timestamp datestr timestr nm370 nm450 nm520 nm590 nm660 nm880 nm950 flow rest; do

    timestamp="$date $time"
    timestamp_unix=$(date -d "$timestamp" +%s)000000000

    write_query="ae31 date_str=$datestr,time_str=$timestr nm370=$nm370,nm450=$nm450,nm520=$nm520,nm590=$nm590,nm660=$nm660,nm880=$nm880,nm950=$nm950,flow=$flow $timestamp_unix"

    echo $write_query

  done < "$file"
done
