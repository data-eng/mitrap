#!/bin/bash

BINDIR="/home/debian/live"
source /home/mitrap/.influx.env

file_to_process=$1
file_to_store=$2

header=$(cat "${file_to_process}" | head -1)
echo "${header},valve_state" > "${file_to_store}"

cat "${file_to_process}" | tail +2 |\
    (while read line
     do
	mytime=$(echo $line | cut -d , -f 252 | tr ' ' 'T')
	q="import \"date\"
	   t1=date.sub(d: 10m, from: $mytime)
	   from(bucket: \"mitrap006\")
		|> range(start: t1, stop: $mytime) 
		|> filter(fn: (r) => r._measurement == \"uf\")
		|> filter(fn: (r) => r._field == \"valve\")
		|> last()
		|> keep(columns: [\"_time\",\"_value\"])"
	echo "Q1 : $q"
	resp=$(influx query --raw --org mitrap --token $MITRAP_READ_TOKEN "$q" | awk '/^[^#]/ && /,/' | tail -1)
	echo "R1: $resp"
	#before_t=$(echo $resp | cut -d, -f 4)
	before_v=$(echo $resp | cut -d, -f 5)
	q="from(bucket: \"mitrap006\")
	        |> range(start: $mytime, stop: now()) 
		|> filter(fn: (r) => r._measurement == \"uf\")
		|> filter(fn: (r) => r._field == \"valve\")
		|> first()
		|> keep(columns: [\"_time\",\"_value\"])"
	echo "Q2: $q"
	# Results have comments and empty lines.
	# Good lines have , and do not start with #
	# The first line is the header and the second is the CSV
	# The CSV is ",result,table,_time,_value", so we need fields 4 and 5
	resp=$(influx query --raw --org mitrap --token $MITRAP_READ_TOKEN "$q" | awk '/^[^#]/ && /,/' | tail -1)
	echo "R2: $resp"
	#after_t=$(echo $resp | cut -d, -f 4)
	after_v=$(echo $resp | cut -d, -f 5)
	if [[ $before_v == $after_v ]]; then
		my_v=${before_v}
	else
		#my_v=$(echo "($t0 - $t1)/($t2 - $t1)*$before_v + ($t2 - $t0)/($t2 - $t1)*$after_v" | bc -l )
		my_v=2
	fi
	#echo "$line,$my_v,$before_t,$before_v,$after_v,$after_t" # DEBUG
	echo "$line,$my_v" >> "${file_to_store}" 
     done) 

exit 0

