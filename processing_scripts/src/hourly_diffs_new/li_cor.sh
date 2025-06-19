#!/bin/bash

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

current_date=""
previous_hour=0

while IFS= read -r line; do

    # If first line - date string
    if [[ "$line" =~ ^\"([0-9]{4}-[0-9]{2}-[0-9]{2})\ at\ ([0-9]{2}): ]]; then
        current_date="${BASH_REMATCH[1]}"
        previous_hour="${BASH_REMATCH[2]}"
        continue
    fi

    # Skip headers
    if [[ "$line" == "Time(H:M:S)"* ]]; then
        continue
    fi

    IFS=$'\t' read -r time co2_ppm temp_c pres_kPA <<< "$line"

    # Extract hour
    hour=${time%%:*}

    # Detect date change
    if (( 10#$hour < 10#$previous_hour )); then
        current_date=$(date -d "$current_date +1 day" +%F)
    fi
    previous_hour=$hour

    timestamp="$current_date $time"
    timestamp_unix=$(date -d "$timestamp" +%s)000000000

    pres_kPA=$(echo "$pres_kPA" | tr -d '\n' | tr -d '\r')

    write_query="li_cor,installation="'"$installation_name"'",instrument="'"${instrument_name}"'"'" co2_ppm=$co2_ppm,temp_c=$temp_c,pres_kPA=$pres_kPA $timestamp_unix"

    echo $write_query >> "$file_to_store"

done < "$file_to_process"
