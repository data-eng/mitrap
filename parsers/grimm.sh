#!/bin/bash

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$installation_name")
instrument_name=$(escape_tag_value "$instrument_name")

# Grimm data comes in chunks of 6sec, where each chunk starts with a P line
# followed up by 40 C/c lines. But sync'ing is not aligned with chunks,
# but happens in the middle of chunks and even lines.
# We spool the unfinished last chunk until the next sync cycle.

# Broken lines are discarded: because we use wc -l to find what is
# new in the incoming folder, the last line does not count towards the
# number of lines in the backup/ folder because it has no \n, therefore
# the file in the new/ folder starts with this line.
# See in sync.sh how OLDLINES and NEWLINES are computed and used to
# decide what to transfer to new/

SPOOL=/mnt/spool
SPOOL=/tmp/

PLINES=$(grep -n '^P' $file_to_process | cut -d: -f 1)
FIRSTPLINE=$(echo $PLINES | tr ' ' '\n' | head -n 1)
LASTPLINE=$(echo $PLINES | tr ' ' '\n' | tail -n 1)

# The data in the spool (if any) and the lines before the first
# PLINE should be 41, if all went well.

cat $file_to_process | head -n $((FIRSTPLINE - 1)) >> ${SPOOL}/grim
if [[ $(cat ${SPOOL}/grim | wc -l) == 41 ]]; then
    mv ${SPOOL}/grim ${file_to_process}.temp
else
    echo "WARNING: Bad spool, deleted."
    rm ${SPOOL}/grim
    rm ${file_to_process}.temp
fi

# The useful data is the lines between the first PLINE and one line
# before the last PLINE

cat $file_to_process | head -n $((LASTPLINE - 1)) | tail -n +${FIRSTPLINE} >> ${file_to_process}.temp

# The next spool is the lines from the last PLINE onwards
cat $file_to_process | tail -n +${LASTPLINE} > ${SPOOL}/tmp
# Keep only the full lines
NFULL=$(cat ${SPOOL}/tmp | wc -l)
cat ${SPOOL}/tmp | head -n ${NFULL} > ${SPOOL}/grim


# Sanity check: all PLINES diffs must be 41
PLINES=$(grep -n '^P' ${file_to_process}.temp | cut -d: -f 1)
PDIFF=$(echo $PLINES | awk 'BEGIN { RS=" "; PREV=0 } { print $0-PREV; PREV=$0 }' | tail -n +2 | uniq)
if [[ x$PDIFF != x41 ]]; then
    BADLINES=$(echo $PLINES | awk 'BEGIN { RS=" "; PREV=0 } { print $0-PREV " " PREV "," $0-1 "d" ; PREV=$0 }' | tail -n +2 | grep -v '^41' | grep -v '^$' | cut -d ' ' -f 2- | tr '\n' ';' | sed 's/;$//')
    echo "Bad lines: ${BADLINES}"
    sed -e "${BADLINES}" < ${file_to_process}.temp > ${file_to_process}.temp2
else
    cp ${file_to_process}.temp ${file_to_process}.temp2
fi

# One P line every minute, followed by 10 blocks of C_: C_; c_: c_; lines,
# where _ is 0-9. Each C_: C_; c_: c_; set is one reading, taken every 6 sec.

# This awk (a) lets P lines fall through (b) collects quads of Cc lines into one line
# (c) drops the last element
# TODO, sanity check 1: C_: C_; c_; should be empy, c_: should be 160
# TODO, sanity check 2: Order of Cc lines must be C_: C_; c_: c_;

cat ${file_to_process}.temp2 | gawk '\
/^P/   { print; }
/^C.:/ { MYLINE = $2; for (i=3; i<NF; i++) MYLINE = MYLINE " " $i; }
/^C.;/ { for (i=2; i<NF; i++) MYLINE = MYLINE " " $i; }
/^c.:/ { for (i=2; i<NF; i++) MYLINE = MYLINE " " $i; }
/^c.;/ { for (i=2; i<NF; i++) MYLINE = MYLINE " " $i; print MYLINE }' >  ${file_to_process}.temp3

# This awk (a) parses the P line into a datetime
# (b) sums up the ten 6-sec lines into one 1-min line
# These values are accumulative, so substract the value
# to the right to get the actual value for each bin.
# The value to the right might be marginally larger,
# which makes no sense, so fix to zero.

cat ${file_to_process}.temp3 | gawk '\
BEGIN  { MYLINE="" }
/^P/   {
         if (MYLINE != "") {
           for (i=1; i<32; i++) {
             v = arr[i]-arr[i+1];
             if (v<0) { v=0.0; }
             MYLINE = MYLINE "," v;
             arr[i]=0.0;
           }
           MYLINE = MYLINE "," arr[32];
           arr[32]=0.0;
           print MYLINE;
         }
         MYLINE = sprintf( "%02d-%02d-%02d %02d:%02d", 2000 + $2, $3, $4, $5, $6 )
       }
!/^P/  {
         for (i=1; i<=32; i++) arr[i] += $i
       }' >  ${file_to_process}.temp4

cat ${file_to_process}.temp4 | (while IFS=',' read -ra line; do
  datetime=${line[0]}
  csv_fields=$( echo ${line[@]:1} | tr ' ' ',' )

#  write_query="grimm,installation=${installation_name},instrument=${instrument_name} ${inf_fields} ${timestamp_unix}"
#  echo $write_query >> "${file_to_store}.lp"

  # CSV line
  echo "${datetime},${installation_name},${instrument_name},${csv_fields}" >> "${file_to_store}.csv"
done)


