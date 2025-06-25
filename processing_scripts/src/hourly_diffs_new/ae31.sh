#!/bin/bash

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

regex='^-?[0-9]+(\.[0-9]+)?$'

while IFS=',' read -r timestamp datestr timestr nm370 nm450 nm520 nm590 nm660 nm880 nm950 flow rest; do

    timestamp_unix=$(date -d "$timestamp" +%s)000000000

    # Make integers float to avoid flux being quirky
    for var in nm370 nm450 nm520 nm590 nm660 nm880 nm950; do
      if [[ "${!var}" =~ ^-?[0-9]+$ ]]; then
        printf -v "$var" '%s.0' "${!var}"
      fi
    done


    write_query='ae31,installation="'"$installation_name"'",instrument="'"${instrument_name}"'"'" date_str=$datestr,time_str=$timestr,nm370=$nm370,nm450=$nm450,nm520=$nm520,nm590=$nm590,nm660=$nm660,nm880=$nm880,nm950=$nm950,flow=$flow $timestamp_unix"

    echo $write_query >> "$file_to_store"

 done < "$file_to_process"
