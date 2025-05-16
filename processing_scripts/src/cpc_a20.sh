#!/bin/bash

if [[ x"$1" == x || x"$2" == x ]]; then explode; fi

mitrap_station=$1
BUCKET=$2

DIRECTORY="/mnt/incoming/$mitrap_station/sambashare/cpc_A20"

valid_files=()

for file in "$DIRECTORY"/*.csv; do
  if [[ "$(basename "$file")" == *.dat ]]; then
    valid_files+=("$file")
  fi
done

# Process each valid file
for file in "${valid_files[@]}"; do
  tail -n +2 "$file" | while IFS=',' read -r datetime concentration dead_time pulses sat_temp condenser_temp optics_temp cabin_temp inlet_p crit_orifice_p nozzle_p liquid_level pulse_ratio total_errors status_error; do


    timestamp_unix=$(date -d "$datetime" +%s)000000000

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

    echo $write_query

  done
done