#!/bin/bash

source /home/mitrap/.influx.env

file_to_process=$1
file_to_store=$2
station_name=$3

header=$(cat "${file_to_process}" | head -1)
echo "${header},valve_state" > "${file_to_store}"

cat "${file_to_process}" | tail +2 |\
    (while read line
     do
	mytime=$(echo $line | cut -d , -f 1 | tr ' ' 'T')
	q="import \"date\"
	   t1=date.sub(d: 3m, from: $mytime)
	   t2=date.add(d: 2m, to: $mytime)
	   from(bucket: \"mitrap006\")
		|> range(start: t1, stop: t2) 
		|> filter(fn: (r) => r._measurement == \"uf\" and r.installation == \"$station_name\" )
		|> filter(fn: (r) => r._field == \"valve\")
		|> keep(columns: [\"_time\",\"_value\"])"
	echo "Q1 : $q"
	# Results have comments and empty lines.
	# Good lines have "," and do not start with "#"
	# The CSV is ",result,table,_time,_value", so we need field 5
	# influx client gives \r line-termination, change to space-separated
	resp=$(influx query --raw --org mitrap --token $MITRAP_READ_TOKEN "$q" | awk '/^[^#]/ && /,/' | cut -d, -f 5 | sed 's|\r$| |g' )
	echo "R1: $resp"
	# There is a header and the values, so if wc -l is 2 we have only one value,
	# wc -l is 3 we have two values.
	# Anything else is an error.
	# Do not sort, if all is well there will be a series of 1's followed
	# by a series of 0's (or vice versa), no mixing.
	num_resp=$(echo $resp | tr ' ' '\n' | uniq | wc -l)
	
	if [[ x$num_resp == x2 ]]; then
	    my_v=$(echo $resp | tr ' ' '\n' | tail -1)
	elif [[ x$num_resp == x3 ]]; then
	    my_v=2
	else
	    echo "ERROR"
	fi
	    
	#echo "$line,$my_v,$before_t,$before_v,$after_v,$after_t" # DEBUG
	echo "$line,$my_v" >> "${file_to_store}" 
     done) 

exit 0

