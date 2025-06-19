#!/bin/bash


# /mnt/incoming/mitrap000/CO2/Data/COM2_Log_*.txt

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

while IFS=',' read -r date time value; do

  timestamp="$date $time"
  timestamp_unix=$(date -d "$timestamp" +%s)000000000

  # Remove square brackets from value
  value="${value#[}"
  value="${value%]}"

  echo "Timestamp : $timestamp_unix"
  echo "Value     : $value"

  write_query='co2,installation="'"$installation_name"'",instrument="'"${instrument_name}"'"'" value=$value $timestamp_unix"
  echo $write_query >> "$file_to_store"

 done < "$file_to_process"
