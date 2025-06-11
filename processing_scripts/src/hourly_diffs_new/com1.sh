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

if [[ ! "$(basename "$file_to_process")" == *COM1* ]]; then
    echo "COM2 are processed from other script."; exit 1
fi

while IFS=',' read -r date time p_psi unit1 p_pa unit2 p_kpa unit3 p_torr unit4 p_inhg unit5 p_atm unit6 p_bar unit7 conc_3_percent label1 conc_c3 label2 conc_5_percent label3 conc_c5 label4 valve_state valve_label; do

    timestamp="$date $time"
    timestamp_unix=$(date -d "$timestamp" +%s)000000000

    # Unix Timestamp: $timestamp_unix
    # Pressure: PSI, Pa, kPa, Torr, inHg, atm, bar
    # Concentration %3, Concentration, Concentration %5, Concentration C5
    # Valve state [0/1]

    write_query="com1 pressure_psi=$p_psi,pressure_pa=$p_pa,pressure_kpa=$p_kpa,pressure_torr=$p_torr,pressure_inhg=$p_inhg,pressure_atm=$p_atm,pressure_bar=$p_bar,conc_3_percent=$conc_3_percent,c3=$conc_c3,conc_5_percent=$conc_5_percent,conc_c5=$conc_c5,valve_state=$valve_state $timestamp_unix"
    echo $write_query >> "$dir_influx_log/com1.txt"

done < "$file_to_process"
