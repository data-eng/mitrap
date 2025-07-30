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

while IFS=',' read -r date time v0 v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 v16 v17 v18 v19 v20 flow_total flow1 flow2 v22 v23 v24\
  uv0 uv1 uv2 uvatn1 b1 b2 b3 b4 b5 blueatn1 g1 g2 g3 g4 g5 greenatn1 r0 r1 r2 r3 r4 redatn1 ir0 ir1 ir2 ir3 ir4 iratn1 \
  uvbc1 uvbc2 uvbcc bluebc1 bluebc2 bluebcc greenbc1 greenbc2 greenbcc redbc1 redbc2 redbcc irbc1 irbc2 irbcc rest
do

  timestamp_unix=$(date -d "$date $time" +%s)000000000

  # Force integer-looking numbers to floats
  for var in flow_total flow1 flow2 bluebcc greenbcc irbcc redbcc uvbcc blueatn1 greenatn1 iratn1 redatn1 uvatn1
do
  if [[ "${!var}" =~ ^-?[0-9]+$ ]]; then
    eval "$var=\"${!var}.0\""
  fi
done


  write_query="ma200,installation=$installation_name,instrument=$instrument_name flow_total=$flow_total,flow1=$flow1,flow2=$flow2,uvatn1=$uvatn1,blueatn1=$blueatn1,greenatn1=$greenatn1,redatn1=$redatn1,iratn1=$iratn1,uvbcc=$uvbcc,bluebcc=$bluebcc,greenbcc=$greenbcc,redbcc=$redbcc,irbcc=$irbcc $timestamp_unix"

  echo "$write_query" >> "$file_to_store"

done < "$file_to_process"

  