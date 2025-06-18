#!/bin/bash

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments [station], [file_to_process], [timestamp_DD] or [file_to_store]." >> /home/mitrap/log/ae31.log
  exit 1
fi

station=$1
file_to_process=$2
timestamp_DD=$3
file_to_store=$4
dir_influx_log="/home/debian/src/mitrap/influx_log/$timestamp_DD/$station"
mkdir -p $dir_influx_log

while IFS=',' read -r timestamp datestr timestr nm370 nm450 nm520 nm590 nm660 nm880 nm950 flow rest; do

    timestamp_unix=$(date -d "$timestamp" +%s)000000000

    write_query="ae31 date_str=$datestr,time_str=$timestr,nm370=$nm370,nm450=$nm450,nm520=$nm520,nm590=$nm590,nm660=$nm660,nm880=$nm880,nm950=$nm950,flow=$flow $timestamp_unix"

    echo $write_query >> "$dir_influx_log/$file_to_store.txt"

 done < "$file_to_process"
