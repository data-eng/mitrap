#!/bin/bash

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

if [[ x"$5" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
station_name=$3
instrument_name=$4
instrument_tz=$5

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV com1: $BINDIR $instrument_tz"


# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$station_name")
instrument_name=$(escape_tag_value "$instrument_name")

if [[ "$(basename "$file_to_process")" == *Event* ]]; then
    echo "We do not process Event files."; exit 1
fi

if [[ ! "$(basename "$file_to_process")" == *COM1* ]]; then
    echo "COM2 are processed from other script."; exit 1
fi

while IFS=',' read -r date time p_psi unit1 p_pa unit2 p_kpa unit3 p_torr unit4 p_inhg unit5 p_atm unit6 p_bar unit7 conc_3_percent label1 conc_c3 label2 conc_5_percent label3 conc_c5 label4 valve_state valve_label; do

    datetime="$date $time"
    timestamp_unix=$(TZ="${instrument_tz}" date -d "$datetime" +%s%N)
    datetime_tz=$(TZ="${instrument_tz}" date --rfc-3339=seconds -d "$datetime")

    # Unix Timestamp: $timestamp_unix
    # Pressure: PSI, Pa, kPa, Torr, inHg, atm, bar
    # Concentration %3, Concentration, Concentration %5, Concentration C5
    # Valve state [0/1]

    write_query="com1,installation=${installation_name},instrument=${instrument_name} pressure_psi=$p_psi,pressure_pa=$p_pa,pressure_kpa=$p_kpa,pressure_torr=$p_torr,pressure_inhg=$p_inhg,pressure_atm=$p_atm,pressure_bar=$p_bar,conc_3_percent=$conc_3_percent,c3=$conc_c3,conc_5_percent=$conc_5_percent,conc_c5=$conc_c5,valve_state=$valve_state $timestamp_unix"
    echo $write_query >> "${file_to_store}.lp"

done < "$file_to_process"
