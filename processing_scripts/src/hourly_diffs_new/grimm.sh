#!/bin/bash

if [[ x"$1" == x || x"$2" == x || x"$3" == x ]]; then
  echo "Missing arguments [station], [timestamp_DD] or [file_to_process]." >> /home/mitrap/log/ae.log
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

