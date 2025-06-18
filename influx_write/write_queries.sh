#!/bin/bash

logger=/home/mitrap/log/influx_write.log

if [[ x"$1" == x || x"$2" == x ]]; then
  echo "Missing arguments [station] or [timestamp_DD] ." >> $logger
  exit 1
fi

source /home/debian/.bashrc

station=$1
timestamp_DD=$2

dir_influx_log="/home/debian/src/mitrap/influx_log/$timestamp_DD/$station"

for file in "$dir_influx_log"/*.txt; do
    influx write --bucket "$station" --org mitrap --token $MITRAP_WRITE_TOKEN --file $file >> $logger
done

