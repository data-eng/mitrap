#!/bin/bash

convert_custom_time_to_iso() {
  local base_date="$1"
  local float_time="$2"

  local hour=$(awk -v t="$float_time" 'BEGIN { printf "%d", int(t) }')
  local min_fraction=$(awk -v t="$float_time" 'BEGIN { printf "%.6f", t - int(t) }')
  local minutes=$(awk -v f="$min_fraction" 'BEGIN { printf "%d", f * 60 }')
  local seconds_fraction=$(awk -v f="$min_fraction" 'BEGIN { printf "%.6f", (f * 60) - int(f * 60) }')
  local seconds=$(awk -v f="$seconds_fraction" 'BEGIN { printf "%d", f * 60 }')
  local normal_time=$(printf "%02d:%02d:%02d" "$hour" "$minutes" "$seconds")
  echo "${base_date} ${normal_time}+00:00"
}

clean_nm() {
  local raw_val="$1"

  # Normalize to numeric, trim trailing zeros but keep at least one decimal digit
  awk -v val="$raw_val" '
  BEGIN {
    split(val, parts, ".")
    int_part = parts[1]
    frac_part = parts[2]

    sub(/0+$/, "", frac_part)

    if (frac_part == "") {
      frac_part = "0"
    }

    printf "nm%s_%s\n", int_part, frac_part
  }'
}


file_to_process=$1
file_to_store=$2
station_name=$3
instrument_name=$4
instrument_tz=$5

temp=$(realpath "$0") && BINDIR=$(dirname "$temp")

echo "ENV mpss_inv: $BINDIR $instrument_tz"


filename=$(basename "$file_to_process")
date_str=$(echo "$filename" | grep -oP '\d{8}')  # Extract YYYYMMDD
date_fmt="${date_str:0:4}-${date_str:4:2}-${date_str:6:2}"

cat "$file_to_process" | sed 's|\r$||' |\
while true; do
  read -r line1 || break
  read -r line2 || break

  # Parse line 1 nanometer (nm) headers
  read -ra fields1 <<< "$line1"
  read -ra fields2 <<< "$line2"

  # Both lines should have the same number of columns
  if [[ ${#fields1[@]} -ne ${#fields2[@]} ]]; then
      echo "ERROR: Mismatch between header line and data"
      continue
  fi

  # Extract fixed columns
  time1="${fields1[0]}"; time2="${fields2[0]}"
  temp1="${fields1[1]}"; temp2="${fields2[1]}"
  press1="${fields1[2]}"; press2="${fields2[2]}"
  other1="${fields1[3]}"; other2="${fields2[3]}"

  # Assert common columns match
  if [[ "$time1" != "$time2" || "$temp1" != "$temp2" || "$press1" != "$press2" || "$other1" != "$other2" ]]; then
      echo "ERROR: Mismatch between header line and metadata"
      continue
  fi

  # Assert the diameters are always the same
  # (storing the header the first time around)
  diameters_now=""
  for ((i = 4; i < ${#fields1[@]}; i++)); do
    diameters_now="${diameters_now},nm_${fields1[$i]}"
  done
  if [[ x${diameters} == x ]]; then
      diameters=${diameters_now}
      num_diameters=$((${#fields1[@]}-4))
      echo "datetime,station_name,instrument_name,num_data_cols,num_meta_cols${diameters},temperature,pressure,other,lineage" > "${file_to_store}.csv"
  elif [[ x${header} != x${header_now} ]]; then
      echo ${header}
      echo ${header_now}
      continue
  fi

  datetime=$(convert_custom_time_to_iso "$date_fmt" "$time1")
  
  meta_fields="${temp1},${press1},${other1}"

  # Loop over data fields
  fields=""
  for ((i = 4; i < ${#fields1[@]}; i++)); do

    nm_raw="${fields1[$i]}"
    val="${fields2[$i]}"

    nm_raw=$(echo "$nm_raw" | tr -d '\n' | tr -d '\r')
    val=$(echo "$val" | tr -d '\n' | tr -d '\r')

    nm_name=$(clean_nm "$nm_raw")
    fields="${fields},${val}"
  done

  echo "${datetime},${station_name},${instrument_name},${num_diameters},3${fields},${meta_fields},${file_to_process}" >> "${file_to_store}.csv"

done

bash ${BINDIR}/valve_finder.sh "${file_to_store}.csv" "${file_to_store}_valve.csv" "${station_name}"

python3 ${BINDIR}/mpss_lp_maker.py "${file_to_store}_valve.csv" > "${file_to_store}.lp"

