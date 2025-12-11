#!/bin/bash

shopt -s lastpipe
source /home/mitrap/.influx.env

file_to_process=$1
file_to_store=$2
station_name=$3

header=$(cat "${file_to_process}" | head -1)
echo "${header},valve_state,valve_state_uf,valve_state_1,valve_state_2,valve_state_3,valve_state_4" > "${file_to_store}"

cat "${file_to_process}" | tail +2 |\
    (while read line
     do
	mytime=$(echo $line | cut -d , -f 1 | tr ' ' 'T')
	q="import \"date\"
        t=${mytime}
	t1=date.sub(d: 11m, from: t)
	t2=date.add(d: 11m, to: t)

	from(bucket: \"mitrap006\")
       |> range(start: t1, stop: t2) 
       |> filter(fn: (r) => r._measurement == \"uf\" and r.installation == \"${station_name}\" and r._field == \"valve\")
       |> keep(columns:[\"_time\",\"_value\"])
       |> duplicate(column: \"_value\", as: \"valve\")
       |> difference()
       |> map(fn: (r) => ( { r with diff:int(v: duration(v: uint(v:r._time)-uint(v:t)))/1000000000 } ) )
       //|> map(fn: (r) => ( { r with diff:string(v: duration(v: uint(v:r._time)-uint(v:t))) } ) )
       |> filter(fn: (r) => r._value != 0 or r.diff > -31 and r.diff < 31 )
       // We want to pivot to a table that gives the previous change, the current value, and the next change
       // Mark these three points.
       |> map(fn: (r) => ( { r with row_id: 67,
                                    poi:
                              if r.diff > -31 and r.diff < 31 then \"state_now\"
                              else if r.diff < 0 then \"state_start\"
                              else \"state_end\",
                                    _value:
                              if r.diff > -31 and r.diff < 31 then int(v:r.valve)
                              else if r.diff < 0 then -r.diff
                              else r.diff,
                               } ) )
       |> pivot( rowKey:[\"row_id\"], columnKey:[\"poi\"], valueColumn:\"_value\" )"
	#echo "Q1 : $q"  # DEBUG LOG
	# Results have comments and empty lines.
	# Good lines have "," and do not start with "#"
	# The CSV is ,result,table,row_id,state_start,state_now,state_end
	# so the useful information is in columns 5-7. Column 4 must be "67"
	# influx client gives \r line-termination, change to space-separated
	resp=$(influx query --raw --org mitrap --token $MITRAP_READ_TOKEN "$q" | awk '/^[^#]/ && /,/' | cut -d, -f 4-7 | sed 's|\r$| |g' )
	#echo "R1: $resp"  # DEBUG LOG

	num_resp=$(echo $resp | tr ' ' '\n' | wc -l)
	if [[ x$num_resp != x2 ]]; then
	    echo "ERROR 1"
	    echo $resp
	    continue
	else
	    # We do not know which of state_start/state_end actually appear, as they might be outside of the 11min range.
	    # It is not OK to just make range longer (eg, 16min), as it would occasionally bring more than one state flip into the table.
	    # The ungrouped pivot works only because there can only by one flip on either side of my_time.
	    echo $resp | tr ' ' '\n' | head -1 | IFS=',' read col0 col1 col2 col3
	    echo $resp | tr ' ' '\n' | tail +2 | IFS=',' read val0 val1 val2 val3
	    if [[ x${col0} != x ]]; then printf -v "${col0}" '%s' "${val0}"; fi
	    if [[ x${col1} != x ]]; then printf -v "${col1}" '%s' "${val1}"; fi
	    if [[ x${col2} != x ]]; then printf -v "${col2}" '%s' "${val2}"; fi
	    if [[ x${col3} != x ]]; then printf -v "${col3}" '%s' "${val3}"; fi
	    if [[ x${row_id} != x67 ]]; then
		echo "ERROR 2: $sixtyseven"
		continue
	    fi
	    #echo "${state_start}"
	    #echo "${state_end}"
	    #echo "${state_now}"
	fi

	# Give the actual valve_state and five scenarios with state "2" (discard measurement)

	# Ultafine rule: Discard 1min before and 2min after the minute during which the valve changed.
	# So state_start must be 3min before my time, start_end must be 2 min after my time
	if [[ ${state_start} > 180 && ${state_end} > 120 ]]; then v0=${state_now}; else v0=2; fi

	# MPSS alternative rules: Discard 1min before and 9/7/5/3min after the minute during which the valve changed
	# So state_start must be 3min before my time, start_end must be 2 min after my time
	if [[ ${state_start} > 240 && ${state_end} > 120 ]]; then v1=${state_now}; else v1=2; fi
	if [[ ${state_start} > 360 && ${state_end} > 120 ]]; then v2=${state_now}; else v2=2; fi
	if [[ ${state_start} > 480 && ${state_end} > 120 ]]; then v3=${state_now}; else v3=2; fi
	if [[ ${state_start} > 600 && ${state_end} > 120 ]]; then v4=${state_now}; else v4=2; fi
	echo "$line,$state_now,$v0,$v1,$v2,$v3,$v4" >> "${file_to_store}" 
     done) 

exit 0

