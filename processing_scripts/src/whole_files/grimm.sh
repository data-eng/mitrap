#!/bin/bash


# Fixed column names: 
  # J :    0.25     0.28     0.30     0.35     0.40     0.45     0.50     0.58
  # J ;    0.65     0.70     0.80     1.00     1.30     1.60     2.0      2.5

cols=(nm0_25 nm0_28 nm0_30 nm0_35 nm0_40 nm0_45 nm0_50 nm0_58 nm0_65 nm0_70 nm0_80 nm1_00 nm1_30 nm1_60 nm2_00 nm2_50)

if [[ x"$1" == x || x"$2" == x ]]; then exit 1; fi

mitrap_station=$1
BUCKET=$2

DIRECTORY="/mnt/incoming/$mitrap_station/sambashare/GrimmOPC107"

for file in "$DIRECTORY"/*.[tT][xX][tT]; do

  filtered_lines=()

  # Keep only P lines and cC lines. It is possible that with these lines interfere
  # some remote control commands we have to filter them accordingly.
  while IFS= read -r line || [[ -n $line ]]; do
    uline="${line//$'\r'/}"
    if [[ "$uline" =~ ^P[[:space:]]+[0-9]{2} ]] || [[ "$uline" =~ ^[cC][0-9] ]]; then
      filtered_lines+=("$uline")
    fi
  done < "$file"

  # Remove all lines before the first P line, as the P line contains the DATE/TIME
  start_index=-1
  for i in "${!filtered_lines[@]}"; do
    line="${filtered_lines[i]}"
    if [[ "$line" =~ ^P[[:space:]]+[0-9] ]]; then
      start_index=$i
      break
    fi
  done

  # If no P line found: skip this file
  if [ "$start_index" -eq -1 ]; then
    continue
  fi

  # Only keep from start_index onward (after first P)
  filtered_lines=("${filtered_lines[@]:$start_index}")

  timestamp_unix=""

  for line in "${filtered_lines[@]}"; do

    # If is P line make the timestamp
    if [[ "$line" =~ ^P[[:space:]]+([0-9]{2}) ]]; then

      read -ra fields <<< "$line"

      # Parse datetime parts from P line
      yy="${fields[1]}"; mm="${fields[2]}"; dd="${fields[3]}";
      HH="${fields[4]}"; MM="${fields[5]}"; SS="${fields[6]}";

      # Convert to full year (2000+)
      year=$((2000 + yy))
      date_str=$(printf "%04d-%02d-%02d %02d:%02d:%02d" "$year" "$mm" "$dd" "$HH" "$MM" "$SS")
      timestamp_unix=$(date -d "$date_str" +%s%N)

      prev_c="none"

      continue
    fi

    # If cC line then map each two lines to the corresponding column names.
    # Also lowercase c only contains an extra column, which we remove
    if [[ "$line" =~ ^[cC][0-9] ]]; then

      cleaned="${line//[:;]/}"
      read -ra values <<< "$cleaned"

      cname=${values[0]}
      values=("${values[@]:1}")

      # For lowercase c ignore last value
      if [[ "${cname:0:1}" == "c" ]]; then
        unset 'values[-1]'
      fi

      if [[ "$prev_c" != "$cname" ]]; then
        fields_1=""
        for i in "${!values[@]}"; do
          val="${values[i]}"; col="${cols[i]}";
          fields_1+=",${col}=${val}"
        done
      else
        fields_2=""
        for i in "${!values[@]}"; do
          j=$((i+8))
          val="${values[i]}"; col="${cols[j]}";
          fields_2+=",${col}=${val}"
        done

        fields_2="${fields_2#,}"

        # Influx line
        write_query="grimm,name=${cname} ${fields_1} ${fields_2} ${timestamp_unix}"
        echo $write_query

      fi

      prev_c=$cname

    fi

  done
done