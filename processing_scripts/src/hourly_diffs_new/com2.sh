#!/bin/bash

if [[ x"$1" == x || x"$2" == x || x"$3" == x ]]; then
  echo "Missing arguments [station], [timestamp_DD] or [file_to_process]."; exit 1
fi

station=$1
file_to_process=$2
timestamp_DD=$3
dir_influx_log="/home/debian/src/mitrap/influx_log/$timestamp_DD/$station"
mkdir -p $dir_influx_log

if [[ "$(basename "$file_to_process")" == *Event* ]]; then
    echo "We do not process Event files."; exit 1
fi

if [[ ! "$(basename "$file_to_process")" == *COM2* ]]; then
    echo "COM1 are processed from other script."; exit 1
fi

regex='^-?[0-9]+(\.[0-9]+)?$'

while IFS=',' read -r date time value; do

  timestamp="$date $time"
  timestamp_unix=$(date -d "$timestamp" +%s)000000000

  value=$(echo "$value" | tr -d '\n' | tr -d '\r')

  if [[ "$value" =~ $regex ]]; then

      if [[ "$value" =~ ^-?[0-9]+$ ]]; then
          value="${value}.0"  # Make integers float to avoid flux being quirky
      fi

      write_query="com2 value=$value $timestamp_unix"
      echo $write_query >> "$dir_influx_log/com2.txt"

  else
      echo "NaN value=$value"
  fi

done < "$file_to_process"
