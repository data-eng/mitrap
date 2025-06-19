#!/bin/bash

DD=$(date +%s)
# Redirect all stdout/stderr to logfile
exec &>> /home/mitrap/log/sync.${DD}.log


BINDIR=/home/debian/src/mitrap
PROCDIR=${BINDIR}/processing_scripts/src/hourly_diffs_new/
CONFIG=/mnt/installations.toml
OUTDIR=/mnt/new

# Read in installations config

declare -A toml
shopt -s lastpipe

cat ${CONFIG} | ${BINDIR}/toml2bash | while read KEY VALUE; do
    toml["$KEY"]=$VALUE
done

KEYS="${!toml[@]}"
INSTALLATIONS=$(echo ${KEYS} | tr ' ' '\n' | sed 's/\..*$//' | sort | uniq)

# fetch data

for inst in ${INSTALLATIONS}; do
	rsync -av --delete ${inst}@mitrap-pc.ipta.demokritos.gr:/sensor_data/MITRAP-DATA/${inst} /mnt/incoming/
done


# Process files

for INST in ${INSTALLATIONS}; do
    echo "===== RUN ${DD} INSTALLATION ${INST}"
    # Find all sub-keys under $INST that have sub-sub-keys (have a dot)
    # The level under $INST is the name of the processor
    # The next level must have 'name', 'file', 'head' third-levels.
    TYPES=$(echo $KEYS | tr ' ' '\n' | grep $INST | sed "s/^$INST\.//" | grep -F '.' | sed 's/\..*$//' | sort | uniq) 
    for TYPE in $TYPES; do
	FIELDS=$(echo $KEYS | tr ' ' '\n' | grep "^${INST}.${TYPE}" | sed "s/^${INST}.${TYPE}.//" | sort | tr '\n' '_')
	if [[ "${FIELDS}" == "file_head_name_" ]]; then
	    mykey="${INST}.${TYPE}.file"
	    FILES=$(ls -d /mnt/incoming/${INST}/${toml[$mykey]} 2>/dev/null | sed "s#/mnt/incoming/##")
	    echo "FILES $FILES from ${toml[$mykey]} for key $mykey"
	    i=0
	    for F in $FILES; do
		DIR="${OUTDIR}/${DD}/"$(dirname "$F")
		echo "FILE $F DIR ${DIR}"
		mkdir -p ${DIR}

                if [[ -f /mnt/backup/$F ]]; then
                    OLDLINES=$(cat "/mnt/backup/$F" | wc -l)
                    NEWLINES=$(cat "/mnt/incoming/$F" | wc -l)
                    echo "LINES $F: $OLDLINES $NEWLINES"
                    # Note that unterminated lines at EOF are ignored by wc
                    # So half-written lines are left behind for the next round.

                    if [[ ${NEWLINES} -gt ${OLDLINES} ]]; then
                        # There are more lines now.

                        # First, copy the header
                        mykey="${INST}.${TYPE}.head"
                        HEADER=${toml[$mykey]}
                        if [[ $HEADER -gt 0 ]]; then
                                echo "CP HEADER $HEADER"
                                head -n ${HEADER} "/mnt/incoming/$F" > "${OUTDIR}/${DD}/$F"
                        fi

                        # Then put the new lines in new/
                        tail -n +$((OLDLINES + 1)) "/mnt/incoming/$F" >> "${OUTDIR}/${DD}/$F"
                    fi

                else
		    # New file, just copy
                    echo "CP -p /mnt/incoming/$F ${DIR}"
                    cp -p /mnt/incoming/$F ${DIR}
                fi


		if [[ -s "${OUTDIR}/${DD}/${F}" ]]; then
		    # The TYPE in the TOML must be identical to the respective processot script
		    INFLUXDIR="/mnt/influxlines/${DD}/${INST}"
		    mkdir -p ${INFLUXDIR}
		    echo "EXEC $PROCDIR/${TYPE}.sh $INST ${OUTDIR}/${DD}/$F ${INFLUXDIR}/${PROC}_${i}.lp"
		    bash ${PROCDIR}/${TYPE}.sh $INST "${OUTDIR}/${DD}/$F" "${INFLUXDIR}/${PROC}_${i}.lp"
		fi

		((i++))
	    done
	else
	    echo "ERROR: ${INST}.${TYPE} should have sub-fields file, head, proc. No more, no less."
	fi
    done
done


rsync -av --delete /mnt/incoming/ /mnt/backup
exit 0
