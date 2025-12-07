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

echo "ENV cpc_a20: $BINDIR $instrument_tz"


# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$station_name")
instrument_name=$(escape_tag_value "$instrument_name")

tail -n +2 "$file_to_process" | while IFS=',' read -r datetime concentration dead_time pulses sat_temp condenser_temp optics_temp cabin_temp inlet_p crit_orifice_p nozzle_p liquid_level pulse_ratio total_errors status_error; do

    datetime_fixed="${datetime//./-}"
    timestamp_unix=$(TZ="${instrument_tz}" date -d "$datetime_fixed" +%s%N)
    datetime_tz=$(TZ="${instrument_tz}" date --rfc-3339=seconds -d "$datetime_fixed")

    status_error=$(echo "$status_error" | tr -d '\n' | tr -d '\r')
    status_error_dec=$((16#${status_error#0x}))

    write_query="cpc_data,installation=${installation_name},instrument=${instrument_name} \
concentration_cc=${concentration},\
dead_time_us=${dead_time},\
pulses=${pulses},\
saturator_temp_C=${sat_temp},\
condenser_temp_C=${condenser_temp},\
optics_temp_C=${optics_temp},\
cabin_temp_C=${cabin_temp},\
inlet_pressure_kPa=${inlet_p},\
critical_orifice_pressure_kPa=${crit_orifice_p},\
nozzle_pressure_kPa=${nozzle_p},\
liquid_level=${liquid_level},\
pulse_ratio=${pulse_ratio},\
total_errors=${total_errors},\
status_error=${status_error_dec} \
$timestamp_unix"

    echo $write_query >> "${file_to_store}.lp"

  done
