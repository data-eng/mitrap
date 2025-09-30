#!/bin/bash

DD=$(date +%s)
# Redirect all stdout/stderr to logfile
exec &>> /home/mitrap/log/sync.${DD}.log

source /home/mitrap/.influx.env

BINDIR=/home/debian/live
PROCDIR=${BINDIR}/parsers/
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



# parse and load YPEN data

YPENINFLUX="/mnt/influxlines/${DD}"
mkdir -p $YPENINFLUX
YPENINFLUX="${YPENINFLUX}/ypen.lp"
LATEST=$(ls /mnt/ypen/*.csv | tail -1)
echo "EXEC ypen.py ${LATEST} ${YPENINFLUX}"
python3 ${PROCDIR}/ypen.py ${LATEST} > ${YPENINFLUX}
/usr/bin/influx write --bucket mitrap006 --org mitrap --token $MITRAP_WRITE_TOKEN -p s --file ${YPENINFLUX}



# fetch MI-TRAP data

for inst in ${INSTALLATIONS}; do
	rsync -av --delete ${inst}@mitrap-pc.ipta.demokritos.gr:/sensor_data/MITRAP-DATA/${inst} /mnt/incoming/
done



# Process files

for INST in ${INSTALLATIONS}; do
    mykey="${INST}.city"
    INSTNAME=${toml[$mykey]}
    echo "===== RUN ${DD} INSTALLATION ${INST} ${INSTNAME}"
    # Find all sub-keys under $INST that have sub-sub-keys (have a dot)
    # The level under $INST is the name of the processor
    # The next level must have 'name', 'file', 'head' third-levels.
    TYPES=$(echo $KEYS | tr ' ' '\n' | grep $INST | sed "s/^$INST\.//" | grep -F '.' | sed 's/\..*$//' | sort | uniq) 
    for TYPE in $TYPES; do
	FIELDS=$(echo $KEYS | tr ' ' '\n' | grep "^${INST}.${TYPE}" | sed "s/^${INST}.${TYPE}.//" | sort | tr '\n' '_')
	if [[ "${FIELDS}" == "file_head_name_" ]]; then
	    mykey="${INST}.${TYPE}.name"
	    INSTRUMENT=${toml[$mykey]}
	    mykey="${INST}.${TYPE}.file"
	    FILES=$(ls -d /mnt/incoming/${INST}/${toml[$mykey]} 2>/dev/null | sed "s#/mnt/incoming/##")
	    echo "INSTRUMENT ${INSTRUMENT} FILES $FILES from ${toml[$mykey]} for key $mykey"
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

                INFLUXDIR="/mnt/influxlines/${DD}/${INST}"
                INFLUXFILE="${INFLUXDIR}/${TYPE}_${i}"

		if [[ -s "${OUTDIR}/${DD}/${F}" ]]; then
		    # The TYPE in the TOML must be identical to the respective processot script
		    mkdir -p ${INFLUXDIR}
		    # Remove DOS line-termintaions in-place
		    echo "$(tr -d '\r' < ${OUTDIR}/${DD}/${F})" > ${OUTDIR}/${DD}/${F}
		    echo "EXEC $PROCDIR/${TYPE}.sh ${OUTDIR}/${DD}/$F ${INFLUXFILE} ${INSTNAME} ${INSTRUMENT}"
		    bash ${PROCDIR}/${TYPE}.sh "${OUTDIR}/${DD}/$F" "${INFLUXFILE}" "${INSTNAME}" "${INSTRUMENT}"
		fi

                # Write Influx lines to DB
		# Careful: INFLUXFILE is the pathname without the suffix
                if [[ -s "${INFLUXFILE}.lp" ]]; then
                    echo "WRITE ${INFLUXFILE}.lp TO INFLUX"
                    /usr/bin/influx write --bucket mitrap006 --org mitrap --token $MITRAP_WRITE_TOKEN --file ${INFLUXFILE}.lp
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
