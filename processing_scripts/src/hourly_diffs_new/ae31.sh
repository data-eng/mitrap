#!/bin/bash

if [[ x"$1" == x || x"$2" == x ]]; then exit 1; fi

mitrap_station=$1
BUCKET=$2

DIRECTORY="/mnt/incoming/$mitrap_station/sambashare/AE31/mitrap"

if [[ x"$1" == x || x"$2" == x ]]; then
  echo "Missing arguments [file_to_process] or [file_influx_log]."; exit 1
fi

station=$1
file_to_process=$2
dir_influx_log="/home/debian/src/mitrap/influx_log/$station"

mkdir -p $dir_influx_log

while IFS=',' read -r timestamp datestr timestr nm370 nm450 nm520 nm590 nm660 nm880 nm950 flow rest; do

    if [[ "$timestamp" == "+ "* ]]; then
        timestamp="${timestamp:2}"
    fi

    timestamp_unix=$(date -d "$timestamp" +%s)000000000

    write_query="ae31 date_str=$datestr,time_str=$timestr nm370=$nm370,nm450=$nm450,nm520=$nm520,nm590=$nm590,nm660=$nm660,nm880=$nm880,nm950=$nm950,flow=$flow $timestamp_unix"

    echo $write_query >> "$dir_influx_log/ae31.txt"

 done < "$file_to_process"
 