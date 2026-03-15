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
bucket_name=$6

if [[ x${bucket_name} == x ]]; then
	bucket_name='mitrap006'
fi

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV ae31: $BINDIR $instrument_tz"

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
station_name_lp=$(escape_tag_value "$station_name")
instrument_name_lp=$(escape_tag_value "$instrument_name")

regex='^-?[0-9]+(\.[0-9]+)?$'

# Many files have error or status lines with date,time,message
# Filter these out. Use grep -a to not drop the complete file
# when it appears as binary (has garbage lines).
cat "${file_to_process}" | grep -a ',.*,.*,' >> "${file_to_store}_temp1"

echo "datetime,station_name,instrument_name,num_calc_col,num_data_col,num_meta_col,concentration_cc,nm_370,nm_450,nm_520,nm_590,nm_660,nm_880,nm_950,date_str,time_str,flow" > "${file_to_store}_temp2"

while IFS=',' read -r datetime datestr timestr nm370 nm450 nm520 nm590 nm660 nm880 nm950 flow rest; do

    timestamp_unix=$(TZ="${instrument_tz}" date -d "$datetime" +%s%N)
    datetime_tz=$(TZ="${instrument_tz}" date --rfc-3339=seconds -d "$datetime")

    # Make integers float to avoid flux being quirky
    for var in nm370 nm450 nm520 nm590 nm660 nm880 nm950; do
      if [[ "${!var}" =~ ^-?[0-9]+$ ]]; then
        printf -v "$var" '%s.0' "${!var}"
      fi
    done

    conc=$( echo "$nm880/1000" | bc -l )
    echo "${datetime_tz},${station_name},${instrument_name},1,7,3,$conc,$nm370,$nm450,$nm520,$nm590,$nm660,$nm880,$nm950,${datestr},${timestr},$flow" >> "${file_to_store}_temp2"

done < "${file_to_store}_temp1"

bash ${BINDIR}/valve_finder.sh "${file_to_store}_temp2" "${file_to_store}.csv" "${station_name}" "${bucket_name}"

python3 ${BINDIR}/bc_lp_maker.py "${file_to_store}.csv" "${station_name}" "${instrument_name}" > "${file_to_store}.lp"

#    echo "ae31,installation=${station_name_lp},instrument=${instrument_name_lp} nm370=$nm370,nm450=$nm450,nm520=$nm520,nm590=$nm590,nm660=$nm660,nm880=$nm880,nm950=$nm950 $timestamp_unix" >> "${file_to_store}.lp"


