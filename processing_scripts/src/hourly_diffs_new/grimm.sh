#!/bin/bash

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments [station], [file_to_process], [timestamp_DD] or [file_to_store]." >> /home/mitrap/log/grimm.log
  exit 1
fi

# Grimm data comes in chunks of 6sec, where each chunk starts with a P line
# followed up by 40 C/c lines. But sync'ing is not aligned with chinks,
# but happens in the middle of chunks and even lines.
# We spool the unfinished last chunk until the next sync cycle.

# Broken lines are discarded: because we use wc -l to find what is
# new in the incoming folder, the last line does not count towards the
# number of lines in the backup/ folder because it has no \n, therefore
# the file in the new/ folder starts with this line.
# See in sync.sh how OLDLINES and NEWLINES are computed and used to
# decide what to transfer to new/

SPOOL=/home/konstant/projects/mitrap/temp/spool

station=$1
file_to_process=$2
timestamp_DD=$3
file_to_store=$4
#dir_influx_log="/home/debian/src/mitrap/influx_log/$timestamp_DD/$station"
dir_influx_log="/home/konstant/projects/mitrap/temp/$timestamp_DD/$station"
mkdir -p $dir_influx_log

PLINES=$(grep -n '^P' $file_to_process | cut -d: -f 1)

echo $PLINES

FIRSTPLINE=$(echo $PLINES | tr ' ' '\n' | head -n 1)
LASTPLINE=$(echo $PLINES | tr ' ' '\n' | tail -n 1)

echo "$FIRSTPLINE $LASTPLINE"

# Sanity check: all PLINES diffs must be 41, except for the first one
PDIFF=$(echo $PLINES | awk 'BEGIN { RS=" "; PREV=0 } { print $0-PREV; PREV=$0 }' | tail -n +2 | uniq)
if [[ x$PDIFF != x41 ]]; then
    echo "Bad lines";
    exit 1;
fi


# The data in the spool (if any) and the lines before the first
# PLINE should be 41, if all went well.

cat $file_to_process | head -n $((FIRSTPLINE - 1)) >> ${SPOOL}/grim
if [[ $(cat ${SPOOL}/grim | wc -l) == 41 ]]; then
    echo "Spool looks good. Kept."
    mv ${SPOOL}/grim ${dir_influx_log}/file
else
    echo "Bad spool. Deleted."
    rm ${SPOOL}/grim
fi

# The useful data is the lines between the first PLINE and one line
# before the last PLINE

cat $file_to_process | head -n $((LASTPLINE - 1)) | tail -n +${FIRSTPLINE} >> ${dir_influx_log}/file

# The next spool is the lines from the last PLINE onwards
cat $file_to_process | tail -n +${LASTPLINE} > ${SPOOL}/tmp
# Keep only the full lines
NFULL=$(cat ${SPOOL}/tmp | wc -l)
cat ${SPOOL}/tmp | head -n ${NFULL} > ${SPOOL}/grim


# Fixed column names: 
  # J :    0.25     0.28     0.30     0.35     0.40     0.45     0.50     0.58
  # J ;    0.65     0.70     0.80     1.00     1.30     1.60     2.0      2.5

cols=(nm0_25 nm0_28 nm0_30 nm0_35 nm0_40 nm0_45 nm0_50 nm0_58 nm0_65 nm0_70 nm0_80 nm1_00 nm1_30 nm1_60 nm2_00 nm2_50)


while IFS= read -r line; do

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
        write_query="grimm,name=${cname} ${fields_1} ${fields_2} ${timestamp_unix}" >> "$dir_influx_log/$file_to_store.txt"

      fi

      prev_c=$cname

    fi

done < "$file_to_process"