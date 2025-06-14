#!/bin/bash

BINDIR=/home/debian/src/mitrap
PROCDIR=${BINDIR}/processing_scripts/src/hourly_diffs_new/
CONFIG=/mnt/installations.toml

# Read in installations config

declare -A toml
shopt -s lastpipe

cat ${CONFIG} | ${BINDIR}/toml2bash | while read KEY VALUE; do
    toml["$KEY"]=$VALUE
done

KEYS="${!toml[@]}"
INSTALLATIONS=$(echo ${KEYS} | tr ' ' '\n' | sed 's/\..*$//' | sort | uniq)

DD=$(date +%s)
LOGFILE=/home/mitrap/log/sync.${DD}.log


# fetch data

echo "INSTALLATIONS: ${INSTALLATIONS}" >> ${LOGFILE}

for inst in ${INSTALLATIONS}; do
	rsync -av --delete ${inst}@mitrap-pc.ipta.demokritos.gr:/sensor_data/MITRAP-DATA/${inst} /mnt/incoming/ > ${LOGFILE} 2>&1
	echo "rsync $inst" >> ${LOGFILE}
done


# Process files

for INST in ${INSTALLATIONS}; do
	echo "XXX $INST" >> ${LOGFILE}
	# Find all sub-keys under $INST that have sub-sub-keys (have a dot)
	# The first level under $INST is ignored.
	# The second level must have 'file', 'proc' third-levels.
	# The actual key second level is not important.
	TYPES=$(echo $KEYS | tr ' ' '\n' | grep $INST | sed "s/^$INST\.//" | grep -F '.' | sed 's/\..*$//' | sort | uniq) 
	for TYPE in $TYPES; do
		FIELDS=$(echo $KEYS | tr ' ' '\n' | grep "^${INST}.${TYPE}" | sed "s/^${INST}.${TYPE}.//" | sort | tr '\n' '_')
		if [[ "${FIELDS}" == "file_head_proc_" ]]; then
			mykey="${INST}.${TYPE}.file"
			FILES=$(ls -d /mnt/incoming/${INST}/${toml[$mykey]} 2>/dev/null | sed "s#/mnt/incoming/##")
			echo "FILES $FILES from ${toml[$mykey]} for key $mykey" >> ${LOGFILE}
			mykey="${INST}.${TYPE}.proc"
			PROC=${toml[$mykey]}
			for F in $FILES; do
				DIR="/mnt/new/${DD}/"$(dirname "$F")
				echo "FILE $F DIR ${DIR}" >> ${LOGFILE}
				mkdir -p ${DIR}

				if [[ -f /mnt/backup/$F ]]; then
					#if [[ $(cat /mnt/incoming/$F | tail -c1  | wc -l) -gt 0 ]] ; then
					#	echo "" >> "/mnt/incoming/$F"
					#fi
					mykey="${INST}.${TYPE}.head"
					HEADER=${toml[$mykey]}
					# Copy HEADER starting lines
					if $((HEADER > 0)); then
						echo "CP HEADER $HEADER"
						head -n ${HEADER} "/mnt/incoming/$F" > "/mnt/new/${DD}/$F"
					fi
					OLDLINES=$(cat "/mnt/backup/$F" | wc -l)
					NEWLINES=$(cat "/mnt/incoming/$F" | wc -l)
					echo "LINES $F: $OLDLINES $NEWLINES" >> ${LOGFILE}
					if [[ ${NEWLINES} -gt ${OLDLINES} ]]; then
						# There are more lines now.
						# Only put the new lines in new/
						tail -n +$((OLDLINES + 1)) "/mnt/incoming/$F" >> "/mnt/new/${DD}/$F"
					fi
					# Note that unterminated lines at EOF are ignored by wc
					# So half-written lines are left behind for the next round.

				else
					echo "CP -p /mnt/incoming/$F ${DIR}" >> ${LOGFILE}
					cp -p /mnt/incoming/$F ${DIR}
				fi

				if [[ -s "/mnt/new/${DD}/${F}" ]]; then
					echo "EXEC $PROCDIR/${PROC}.sh $INST /mnt/new/${DD}/$F ${DD}" >> ${LOGFILE}
					sh ${PROCDIR}/${PROC}.sh $INST "/mnt/new/${DD}/$F" ${DD}
				fi
			done
		else
			echo "ERROR: ${INST}.${TYPE} should have sub-fields file, head, proc. No more, no less." >> ${LOGFILE}
		fi
	done
done


rsync -av --delete /mnt/incoming/ /mnt/backup
exit 0

