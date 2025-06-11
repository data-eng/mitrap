#!/bin/bash

if [[ x"$1" == x || x"$2" == x ]]; then
  echo "Missing arguments [station] or [file_to_process]."; exit 1
fi

station=$1
file_to_process=$2
dir_influx_log="/home/debian/src/mitrap/influx_log/$station"

mkdir -p $dir_influx_log


tail -n +2 "$file_to_process" | while IFS=',' read -r datetime concentration dead_time pulses sat_temp condenser_temp optics_temp cabin_temp inlet_p crit_orifice_p nozzle_p liquid_level pulse_ratio total_errors status_error; do

    if [[ "$datetime" == "! "* ]]; then
      datetime="${datetime:2}"
    fi

    datetime_fixed="${datetime//./-}"
    timestamp_unix=$(date -d "$datetime_fixed" +%s)000000000

    status_error=$(echo "$status_error" | tr -d '\n' | tr -d '\r')
    status_error_dec=$((16#${status_error#0x}))

    write_query="cpc_data \
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

    echo $write_query >> "$dir_influx_log/cpc_a20.txt"


  done