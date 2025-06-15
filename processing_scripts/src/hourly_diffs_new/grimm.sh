#!/bin/bash

if [[ x"$1" == x || x"$2" == x || x"$3" == x ]]; then
  echo "Missing arguments [station], [timestamp_DD] or [file_to_process]." >> /home/mitrap/log/ae.log
  echo "Arg 1: x$1" >> /home/mitrap/log/ae.log
  echo "Arg 2: x$2" >> /home/mitrap/log/ae.log
  echo "Arg 3: x$3" >> /home/mitrap/log/ae.log
  exit 1
fi

station=$1
file_to_process=$2
timestamp_DD=$3
dir_influx_log="/home/debian/src/mitrap/influx_log/$timestamp_DD/$station"
mkdir -p $dir_influx_log

echo "Grimm: $dir_influx_log" >> /home/mitrap/log/grimm.$timestamp_DD.log

