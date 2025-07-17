#!/bin/bash

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val"
}

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$3")
instrument_name=$(escape_tag_value "$4")

while IFS=',' read -r date time serial session data_format firmware datetime offset ymd hms gps_lat gps_long gps_alt gps_speed gps_sat timebase status battery ax ay az tape flow_setpoint flow_total flow1 flow2 temp rh dew pressure int_temp opt_conf \
  uv1 uv2 uvref uvatn1 uvatn2 uvk \
  blue1 blue2 blueref blueatn1 blueatn2 bluek \
  green1 green2 greenref greenatn1 greenatn2 greenk \
  red1 red2 redref redatn1 redatn2 redk \
  ir1 ir2 irref iratn1 iratn2 irk \
  uvbc1 uvbc2 uvbcc bluebc1 bluebc2 bluebcc greenbc1 greenbc2 greenbcc redbc1 redbc2 redbcc irbc1 irbc2 irbcc
do

  timestamp_unix=$(date -d "$date $time" +%s)000000000

  # Force integer-looking numbers to floats
  for var in uvbc1 uvbc2 uvbcc bluebc1 bluebc2 bluebcc greenbc1 greenbc2 greenbcc redbc1 redbc2 redbcc irbc1 irbc2 irbcc; do
    if [[ "${!var}" =~ ^-?[0-9]+$ ]]; then
      printf -v "$var" '%s.0' "${!var}"
    fi
  done

  write_query="ma200,installation=$installation_name,instrument=$instrument_name uv1=$uv1,uv2=$uv2,uvref=$uvref,uvatn1=$uvatn1,uvatn2=$uvatn2,uvk=$uvk,blue1=$blue1,blue2=$blue2,blueref=$blueref,blueatn1=$blueatn1,blueatn2=$blueatn2,bluek=$bluek,green1=$green1,green2=$green2,greenref=$greenref,greenatn1=$greenatn1,greenatn2=$greenatn2,greenk=$greenk,red1=$red1,red2=$red2,redref=$redref,redatn1=$redatn1,redatn2=$redatn2,redk=$redk,ir1=$ir1,ir2=$ir2,irref=$irref,iratn1=$iratn1,iratn2=$iratn2,irk=$irk,uvbc1=$uvbc1,uvbc2=$uvbc2,uvbcc=$uvbcc,bluebc1=$bluebc1,bluebc2=$bluebc2,bluebcc=$bluebcc,greenbc1=$greenbc1,greenbc2=$greenbc2,greenbcc=$greenbcc,redbc1=$redbc1,redbc2=$redbc2,redbcc=$redbcc,irbc1=$irbc1,irbc2=$irbc2,irbcc=$irbcc $timestamp_unix"

  echo "$write_query" >> "$file_to_store"

done < "$file_to_process"

  