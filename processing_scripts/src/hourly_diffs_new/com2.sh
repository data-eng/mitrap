#!/bin/bash

if [[ x"$1" == x || x"$2" == x ]]; then 
  echo "Missing arguments [file_to_process] or [file_influx_log]."; exit 1
fi

file_to_process=$1
file_influx_log=$2

if [[ ! "$(basename "$file_influx_log")" == *.txt ]]; then
    echo "Write file must be .txt ."; exit 1
fi

# The following lines are expected to be moved to parcer
if [[ "$(basename "$file_to_process")" == *Event* ]]; then
    echo "We do not process Event files."; exit 1
fi

if [[ ! "$(basename "$file_to_process")" == COM2* ]]; then
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
      echo $write_query > file_influx_log

  else
      echo "NaN value=$value"
  fi

done < "$file_to_process"
