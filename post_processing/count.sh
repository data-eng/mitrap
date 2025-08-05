#!/bin/bash

DD=$(date +%s)

# This job is cron'ed at 21:45 UTC, which is just after midnight EEST
# So the 24 latest influxlines files will be the 24 hours leading
# up to 00:17, since the sync job is cron'ed hourly at :17
DISPLAY_DATE=$(date --date=@$DD --iso-8601)

# Redirect all stdout/stderr to logfile
exec &>> /home/mitrap/log/count.${DD}.log

BINDIR=/home/debian/src/mitrap
CONFIG=/mnt/installations.toml
INFLUXDIR=/mnt/influxlines
OUTDIR=/mnt/statistics/
OUTFILE=${OUTDIR}/counts_${DISPLAY_DATE}_univar.csv

# Read in installations config

declare -A toml
shopt -s lastpipe

cat ${CONFIG} | ${BINDIR}/toml2bash | while read KEY VALUE; do
    toml["$KEY"]=$VALUE
done

KEYS="${!toml[@]}"
INSTALLATIONS=$(echo ${KEYS} | tr ' ' '\n' | sed 's/\..*$//' | sort | uniq)

# Find the relevant timestamps (last 24h)

TT=$(ls $INFLUXDIR | tail -n 24)
echo "On ${DISPLAY_DATE} using files: ${TT}"

# Accumulate results
# Careful: Whan starting fresh, touch an empty file
LATEST_FILE=$(ls -tr ${OUTDIR}/*univar.csv |tail -1)
cp ${LATEST_FILE} ${OUTFILE}

# Count influx lines

for INST in ${INSTALLATIONS}; do
    mykey="${INST}.city"
    INSTNAME=${toml[$mykey]}
    # Find all sub-keys under $INST that have sub-sub-keys (have a dot)
    # The level under $INST is the name of the processor
    # The next level must have 'name', 'file', 'head' third-levels.
    TYPES=$(echo $KEYS | tr ' ' '\n' | grep $INST | sed "s/^$INST\.//" | grep -F '.' | sed 's/\..*$//' | sort | uniq) 
    for TYPE in $TYPES; do
	FIELDS=$(echo $KEYS | tr ' ' '\n' | grep "^${INST}.${TYPE}" | sed "s/^${INST}.${TYPE}.//" | sort | tr '\n' '_')
	if [[ "${FIELDS}" == "file_head_name_" ]]; then
	    mykey="${INST}.${TYPE}.name"
	    INSTRUMENT=${toml[$mykey]}
	    LINES=$( (for T in $TT; do cat ${INFLUXDIR}/${T}/${INST}/${TYPE}_*.lp 2>/dev/null; done) | wc -l )
	    echo "${DISPLAY_DATE},${INSTNAME},${INSTRUMENT},$LINES" >> ${OUTFILE}
	else
	    echo "ERROR: ${INST}.${TYPE} should have sub-fields file, head, proc. No more, no less."
	fi
    done
done

# Prepare condensed format
python3 ${BINDIR}/condense.py ${OUTFILE} ${OUTDIR}/counts_${DISPLAY_DATE}.csv

# Rotate the log
ls -t ${OUTDIR} | tail -2 | sed "s#^#${OUTDIR}#" | xargs rm

# Sync with mitrap-pc
rsync -av --delete ${OUTDIR}/ vima@mitrap-pc.ipta.demokritos.gr:statistics/

exit 0

