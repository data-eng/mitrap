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

SPOOL=/mnt/spool

station=$1
file_to_process=$2
timestamp_DD=$3
file_to_store=$4
dir_influx_log="/home/debian/src/mitrap/influx_log/$timestamp_DD/$station"
mkdir -p $dir_influx_log

PLINES=$(grep -n '^P' $file_to_process | cut -d: -f 1)

FIRSTPLINE=$(echo $PLINES | tr ' ' '\n' | head -n 1)
LASTPLINE=$(echo $PLINES | tr ' ' '\n' | tail -n 1)

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
    mv ${SPOOL}/grim ${file_to_process}.temp
else
    echo "WARNING: Bad spool, deleted."
    rm ${SPOOL}/grim
    rm -f ${file_to_process}.temp
fi

# The useful data is the lines between the first PLINE and one line
# before the last PLINE

cat $file_to_process | head -n $((LASTPLINE - 1)) | tail -n +${FIRSTPLINE} >> ${file_to_process}.temp

# The next spool is the lines from the last PLINE onwards
cat $file_to_process | tail -n +${LASTPLINE} > ${SPOOL}/tmp
# Keep only the full lines
NFULL=$(cat ${SPOOL}/tmp | wc -l)
cat ${SPOOL}/tmp | head -n ${NFULL} > ${SPOOL}/grim


mv ${file_to_process}.temp ${file_to_process}


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

    else

      cleaned="${line//[:;]/}"
      read -ra values <<< "$cleaned"

      cname=${values[0]}
      values=("${values[@]:1}")

      fields1=""
      for i in "${!values[@]}"; do
        val="${values[i]}"; col="${cols[i]}";
        fields1+="${col}=${val},"
      done
      fields=$(echo $fields1|sed 's/,$//')

      # Influx line
      write_query="grimm,name=${cname} ${fields} ${timestamp_unix}"
      echo $write_query >> "$dir_influx_log/$file_to_store.txt"

    fi

done < <( cat $file_to_process | gawk '/P/ { Q=0; print; } /^[Cc]/ { if (Q%4 == 0) { MYLINE = $1; for (i=2; i<NF; i++) MYLINE = MYLINE " " $i ; Q=Q+1 ; } else if  (Q%4==1) { for (i=2; i<NF; i++) MYLINE = MYLINE " " $i ; Q=Q+1; print MYLINE } else if  (Q%4==2) { MYLINE = $1; for (i=2; i<NF-1; i++) MYLINE = MYLINE FS $i ; Q=Q+1 } else if  (Q%4==3) { for (i=2; i<NF; i++) MYLINE= MYLINE " " $i ; Q=Q+1; print MYLINE } } ' )

# The awk script (a) lets P lines fall through (b) collects pairs of Cc lines into one line
# (c) drops the last element of the first line of a c pair (TODO: sanity check, must be 160)


