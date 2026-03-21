#!/bin/bash

BINDIR=/home/debian/live

# This job is cron'ed at 23:50 UTC, to process the results
# from all sync jobs of the day:
# Find the most recent file matching /mnt/spool/stats_*
LATEST=$(ls -tr /mnt/spool/stats_* | tail -1)
DD=$(echo $LATEST | sed 's|/mnt/spool/stats_\(....\)\(..\)\(..\)|\1-\2-\3|')

# Redirect all stdout/stderr to logfile
exec &>> /home/mitrap/log/count.${DD}.log

OUTDIR=/mnt/statistics
ARCHIVEDIR=/mnt/statistics_lp
TEMPFILE=/tmp/counts_${DD}.temp 
OUTFILE=${OUTDIR}/counts_${DD}_univar.csv

# Group-by

python3 << END
import pandas
pandas.read_csv("${LATEST}",sep=" ",header=None).groupby(0).sum().to_csv("${TEMPFILE}",sep=" ",header=None)
END

cat "${TEMPFILE}" | sed 's|,installation=| |' | sed 's|,instrument=| |' |\
	tr ' ' ',' | tr '_' ' ' | sed "s|^|${DD},|" > "${OUTFILE}"
rm "${TEMPFILE}"

# Prepare condensed format
python3 ${BINDIR}/post_processing/condense.py ${OUTFILE} ${OUTDIR}/counts_${DD}.csv

# Archive and load into influx
cp -p ${OUTFILE} ${ARCHIVEDIR}/counts_${DD}.csv

# Rotate the log
ls -t ${OUTDIR} | tail -2 | sed "s#^#${OUTDIR}/#" | xargs rm

# Sync with mitrap-pc
rsync -av --delete ${OUTDIR}/ vima@mitrap-pc.ipta.demokritos.gr:statistics/

exit 0

