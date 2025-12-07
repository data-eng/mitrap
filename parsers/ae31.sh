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

echo "ENV ae31: $BINDIR $instrument_tz"

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
station_name_lp=$(escape_tag_value "$station_name")
instrument_name_lp=$(escape_tag_value "$instrument_name")

regex='^-?[0-9]+(\.[0-9]+)?$'

echo "datetime,station_name,instrument_name,num_data_col,num_meta_col,nm_370,nm_450,nm_520,nm_590,nm_660,nm_880,nm_950,date_str,time_str,flow" > "${file_to_store}.csv"

while IFS=',' read -r datetime datestr timestr nm370 nm450 nm520 nm590 nm660 nm880 nm950 flow rest; do

    timestamp_unix=$(TZ="${instrument_tz}" date -d "$datetime" +%s%N)
    datetime_tz=$(TZ="${instrument_tz}" date --rfc-3339=seconds -d "$datetime")

    # Make integers float to avoid flux being quirky
    for var in nm370 nm450 nm520 nm590 nm660 nm880 nm950; do
      if [[ "${!var}" =~ ^-?[0-9]+$ ]]; then
        printf -v "$var" '%s.0' "${!var}"
      fi
    done

    echo "${datetime_tz},${station_name},${instrument_name},7,3,$nm370,$nm450,$nm520,$nm590,$nm660,$nm880,$nm950,${datestr},${timestr},$flow" >> "${file_to_store}.csv"
    echo "ae31,installation=${station_name_lp},instrument=${instrument_name_lp} nm370=$nm370,nm450=$nm450,nm520=$nm520,nm590=$nm590,nm660=$nm660,nm880=$nm880,nm950=$nm950 $timestamp_unix" >> "${file_to_store}.lp"

 done < "$file_to_process"

