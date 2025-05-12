#!/bin/bash

mitrap_station=$1
BUCKET=$2

DIRECTORY="/mnt/incoming/$mitrap_station/MStack_Flow_Meter_Valve_RHT"

valid_files=()

# Get all text files
for file in "$DIRECTORY"/*.txt
do
  # Check if it is not an event file
  if [[ ! "$(basename "$file")" == *Event* ]]; then
    valid_files+=("$file")
  fi
done

# DO NOT STORE DOUBLE ENTRIES IN THE DB

# Start writing to influx

#TOKEN=TBD
ORG="mitrap"

regex='^-?[0-9]+(\.[0-9]+)?$'

# Loop through all files starting with COM2
for file in "${valid_files[@]}"; do

  if [[ $(basename "$file") == COM2* ]]; then

      while IFS=',' read -r date time value; do

        timestamp="$date $time"
        timestamp_unix=$(date -d "$timestamp" +%s)

        value=$(echo "$value" | tr -d '\n' | tr -d '\r')

        if [[ "$value" =~ $regex ]]; then

            if [[ "$value" =~ ^-?[0-9]+$ ]]; then
                value="${value}.0"  # Make integers float to avoid flux being quirky
            fi

            write_query="com2 value=$value $timestamp_unix"
            echo $write_query
            #echo "$write_query" | influx write --org "$ORG" --bucket "$BUCKET" --token "$TOKEN" --precision s

        else
            echo "NaN value=$value"
        fi

        sleep 1

      done < "$file"
   fi
done

echo "Data processing completed."
