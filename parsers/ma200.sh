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

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$station_name")
instrument_name=$(escape_tag_value "$instrument_name")

while IFS=',' read -r \
    date time serial_number datum_id session_id data_format_version firmware_version date_utc timezone_offset \
    gps_lat gps_long gps_speed timebase status battery_remaining accel_x accel_y accel_z tape_position \
    flow_setpoint flow_total flow1 flow2 sample_temp sample_rh sample_dewpoint internal_pressure internal_temp optical_config \
    uv_sen1 uv_sen2 uv_ref uvatn1 uv_atn2 uv_k \
    blue_sen1 blue_sen2 blue_ref blueatn1 blue_atn2 blue_k \
    green_sen1 green_sen2 green_ref greenatn1 green_atn2 green_k \
    red_sen1 red_sen2 red_ref redatn1 red_atn2 red_k \
    ir_sen1 ir_sen2 ir_ref iratn1 ir_atn2 ir_k \
    uv_bc1 uv_bc2 uvbcc blue_bc1 blue_bc2 bluebcc green_bc1 green_bc2 greenbcc red_bc1 red_bc2 redbcc ir_bc1 ir_bc2 irbcc \
    uv_bc1_smooth uv_bcc_smooth blue_bc1_smooth blue_bcc_smooth ir_bc1_smooth ir_bcc_smooth \
    cref aae_wb aae_ff bcc_wb bcc_ff aae bb delta_c pump_drive reporting_temp reporting_pressure wifi_rssi cksum
do

  datetime="$date $time"
  timestamp_unix=$(TZ="${instrument_tz}" date -d "$datetime" +%s%N)
  datetime_tz=$(TZ="${instrument_tz}" date --rfc-3339=seconds -d "$datetime")

  values=""

  # Force integer-looking numbers to floats
  for var in flow_total flow1 flow2 bluebcc greenbcc irbcc redbcc uvbcc blueatn1 greenatn1 iratn1 redatn1 uvatn1 sample_temp sample_rh bcc_wb bcc_ff
  do
    if [[ x${!var} == x ]]; then continue
    elif [[ "${!var}" =~ ^-?[0-9]+$ ]]; then
      values="${values},${var}=${!var}.0"
    else
      values="${values},${var}=${!var}"
    fi
  done
  values=${values#,}

  if [[ x${values} != x ]]; then
    write_query="ma200,installation=$installation_name,instrument=$instrument_name ${values} $timestamp_unix"
    echo $write_query >> "${file_to_store}.lp"
  fi

done < "$file_to_process"

