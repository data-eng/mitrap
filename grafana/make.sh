#!/bin/bash

prepare_query() {
    cat queries/$1.flux |\
	sed 's|"|\"|' |\
	sed 's|$|\\|g' | tr '\n' 'n'
}

#$(escape_tag_value "$installation_name")

#prepare_query ${Q_nanodust}

if [[ x$1 == xmitrap000 ]]; then
    TEMPLATE="CE_template.json"
    ID=6
    STATION="Athens - Piraeus - CE"
    TITLE="AQM-CE: Athens Piraeus"
    CAMPAIGN="Athens"
    CATEGORY="Port"
elif  [[ x$1 == xmitrap001 ]]; then
    TEMPLATE="CE_template.json"
    ID=7
    STATION="Athens - Aristotelous - CE"
    TITLE="AQM-CE: Athens Aristotelous"
    CAMPAIGN="Athens"
    CATEGORY="Traffic"
elif  [[ x$1 == xmitrap006 ]]; then
    TEMPLATE="HR_template.json"
    ID=3
    STATION="Athens - Patission - HR"
    TITLE="AQM-HR: Athens Patission"
    CAMPAIGN="Athens"
    CATEGORY="Traffic"
else
    echo "bad arg 1"
    exit 1
fi

if [[ x$2 == x ]]; then
    echo "Bad arg 2"
    exit 1
elif [[ x$2 == xAQM ]]; then
    TEMPLATE="AQM-${TEMPLATE}"
elif [[ x$2 == xTSO ]]; then
    TEMPLATE="TSO-${TEMPLATE}"
fi

if [[ x$3 == x ]]; then
    echo "Bad arg 3"
    exit 1
else
    OUTFILE=$3
fi

cat ${TEMPLATE} |\
    sed "s|@ID_INT@|${ID}|g" |\
    sed "s|@STATION_STR@|${STATION}|g" |\
    sed "s|@CAMPAIGN_STR@|${CAMPAIGN}|g" |\
    sed "s|@CATEGORY_STR@|${CATEGORY}|g" |\
    sed "s|@TITLE_STR@|${TITLE}|g" > ${OUTFILE}
    
