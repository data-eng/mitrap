#!/bin/bash

if [[ x"$1" == x || x"$2" == x ]]; then explode; fi

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

for file in "${valid_files[@]}"; do

  if [[ $(basename "$file") == COM1* ]]; then

    while IFS=',' read -r date time p_psi unit1 p_pa unit2 p_kpa unit3 p_torr unit4 p_inhg unit5 p_atm unit6 p_bar unit7 conc_3_percent label1 conc_c3 label2 conc_5_percent label3 conc_c5 label4 valve_state valve_label; do

        timestamp="$date $time"
        timestamp_unix=$(date -d "$timestamp" +%s)000000000

        # Unix Timestamp: $timestamp_unix
        # Pressure: PSI, Pa, kPa, Torr, inHg, atm, bar
        # Concentration %3, Concentration, Concentration %5, Concentration C5
        # Valve state [0/1]

        write_query="com1 pressure_psi=$p_psi,pressure_pa=$p_pa,pressure_kpa=$p_kpa,pressure_torr=$p_torr,pressure_inhg=$p_inhg,pressure_atm=$p_atm,pressure_bar=$p_bar,conc_3_percent=$conc_3_percent,c3=$conc_c3,conc_5_percent=$conc_5_percent,conc_c5=$conc_c5,valve_state=$valve_state $timestamp_unix"
        echo $write_query

    done < "$file"
  fi
done
