#!/bin/bash

BINDIR=/home/debian/src/mitrap
PROCDIR=${BINDIR}/processing_scripts/src/hourly_diffs_new/
CONFIG=/mnt/installations.toml

OUTDIR=/home/user/counts/
INFLUXDIR=/mnt/temp/
mkdir -p ${OUTDIR}
#mkdir -p ${INFLUXDIR}

# Read in installations config

declare -A toml
shopt -s lastpipe

cat ${CONFIG} | ${BINDIR}/toml2bash | while read KEY VALUE; do
    toml["$KEY"]=$VALUE
done

KEYS="${!toml[@]}"
INSTALLATIONS=$(echo ${KEYS} | tr ' ' '\n' | sed 's/\..*$//' | sort | uniq)


for INST in ${INSTALLATIONS}; do
    mykey="${INST}.city"
    INSTNAME=${toml[$mykey]}
    echo "===== INSTALLATION ${INST} ${INSTNAME}"
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
            mkdir -p ${INFLUXDIR}/${INST}
		    bash ${PROCDIR}/${TYPE}.sh /mnt/incoming/$F "${INFLUXDIR}/${INST}/${TYPE}_${i}.lp" "${INSTNAME}" "${INSTRUMENT}"
		    ((i++))
	    done
  	    LINES=$( cat ${INFLUXDIR}/${INST}/${TYPE}_*.lp | wc -l )
	    echo "${INSTNAME},${INSTRUMENT},$LINES" >> ${OUTDIR}/univar.csv
  	    #rm -f ${INFLUXDIR}/${INST}/${TYPE}_*.lp
	else
	    echo "ERROR: ${INST}.${TYPE} should have sub-fields file, head, proc. No more, no less."
	fi
    done
done

exit 0
