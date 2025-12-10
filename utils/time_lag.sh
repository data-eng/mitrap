INFLUXDIR=$1

find "${INFLUXDIR}" -type f -name '*.lp' -print0 |
  while IFS= read -r -d '' line; do
	  if [[ $line =~ mitrap[0-9][0-99][0-9]/ ]]; then
		MITRAP=$(echo $line|sed 's|^.*\(mitrap[0-9][0-9][0-9]\).*$|\1|')
		MEASUREMENT=$(echo $line|sed 's|^.*mitrap[0-9][0-9][0-9]/\(.*\)_[0-9][0-9]*.lp$|\1|')

		last_timestamp=$(tail -1 $line | sed 's|\(\\.\)|_|g' | cut -sd ' ' -f 3)
		file_timestamp=$(date '+%s%N' -r $line)
		file_datetime=$(date --rfc-3339='seconds' -r $line)

		if [[ x$last_timestamp != x ]]; then
			diff=$( echo "($file_timestamp-$last_timestamp)/60/1000000000"| bc)
		fi

		echo $MITRAP,$MEASUREMENT,$file_datetime,$diff
	  fi
  done

exit 0




