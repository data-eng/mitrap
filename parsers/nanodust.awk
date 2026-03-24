BEGIN {
	FS = ","
	n = 0
	acc_pn = 0
	prev_mode = "IMPOSSIBLE MODE"
	print "datetime,concentration_cc,valve_state"
}

{
	mode = $3
	if( mode != prev_mode ) {
		if( n > 0 ) {
			if( prev_mode == "SPN" ) {
				print( start_time "," end_time "," acc_pn/n ",0" )
			}
			else if( prev_mode == "TPN" ) {
				print( start_time "," end_time "," acc_pn/n ",1" )
			}
		}
		start_time = $1
		acc_pn = 0
		n = 0
	}
	n += 1
	end_time = $1
	prev_mode = mode
	acc_pn += $4
}

