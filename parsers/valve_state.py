import sys
import numpy
import pandas

infile = sys.argv[1]
outfile = sys.argv[2]

df = pandas.read_csv( infile, parse_dates=["datetime"],  )

#tt = (df.datetime.values.astype(numpy.int64) * 1e-9).astype(numpy.int64) 
tt = df.datetime.apply(lambda t: t.timestamp())
vv = df.valve_state.astype(numpy.int64)

# Up to 3 steps before and 20 after
# Should be enough for 1min before and 9min after
# (they usually come 1min appart, but often closer together)

# Initialize an array with one empty column,
# then the original data, and then 9 empty columns
n = 20
m = 3
tt_n = numpy.empty( (tt.shape[0],n+m+1), int )
tt_n[:,n] = tt
vv_n = numpy.empty( (vv.shape[0],n+m+1), int )
vv_n[:,n] = vv

# Roll the values and time to get columns with
# prev and next times/values.
# Now each row is a sequence starting n timepoints
# before "now", then "now", then m timepoints
# after "now"

for s in range(n-1,-1,-1):
    tt_n[:,s] = numpy.roll( tt_n[:,s+1], 1 )
    tt_n[0,s] = -1
    vv_n[:,s] = numpy.roll( vv_n[:,s+1], 1 )
    vv_n[0,s] = -1

for s in range(n+1,n+m+1):
    tt_n[:,s] = numpy.roll( tt_n[:,s-1], -1 )
    tt_n[-1,s] = -1
    vv_n[:,s] = numpy.roll( vv_n[:,s-1], -1 )
    vv_n[-1,s] = -1

# Turn absolute times in diff from the "now" column
# but invalidate cells with -1

for s in range(n-1,-1,-1):
    tt_n[:,s] = tt_n[:,n]-tt_n[:,s]
for s in range(n+1,n+m+1):
    tt_n[:,s] = tt_n[:,s]-tt_n[:,n]
tt_n[vv_n==-1] = -1

# Count the number of times we have sufficient datapoints
# If tolerable, continue

pass

# Each column becomes T/F on whether is it the same
# as the "now" column. Columns with -1 will never
# match "now", so they all F.

for i in range(n):
    vv_n[:,i] = (vv_n[:,n] == vv_n[:,i])
for i in range(n+1,n+m+1):
    vv_n[:,i] = (vv_n[:,n] == vv_n[:,i])

# the cumsum is the same as the index iff we have consequetive T's
# ie, for consequtive T's from "now" to the right and left.
# (reversing the viewpoint when cumsum'ing to the left)

after = numpy.cumsum( vv_n[:,n+1:], axis=1 )
temp = numpy.empty( (vv_n.shape[0],n), int )
for i in range(n):
    temp[:,i] = vv_n[:,n-i-1]
before = numpy.cumsum( temp, axis=1 )

# Careful: the "before" values are flipped to satisfy
# how cumsum works, so the closest to "now" is in column 0
# We will flip this back to the previous order
# so that vv_n remain mappable to tt_n

for i in range(1,n+1):
    vv_n[:,n-i] = (before[:,i-1] == i)
for i in range(1,m+1):
    vv_n[:,n+i] = (after[:,i-1] == i)

# Now map to the array of times, to find for how long
# to the left and to the right we have the same value

good_times = numpy.where( vv_n, tt_n, numpy.zeros(tt_n.shape) )
before = numpy.amax( good_times[:,0:n], axis=1 )
after = numpy.amax( good_times[:,n+1:-1], axis=1 ) 

# Now put back an array with times and valve values for
# different policies:
# valve2: valve change invalidates 1min before it and 2min after it.
# therefore, "now" must have 2min before it and 1min good minute afterit
bad = numpy.array( [2]*vv.shape[0] )
df["valve2"] = numpy.where( (before>=2*60) & (after>=60), vv, bad )

# valve3: valve change invalidates 1min before it and 3min after it.
# therefore, "now" must have 3min before it and 1min good minute afterit
df["valve3"] = numpy.where( (before>=3*60) & (after>=60), vv, bad )

# valve5: 5 good min before, 1 good min after "now"
df["valve5"] = numpy.where( (before>=5*60) & (after>=60), vv, bad )

# valve7: i7 good minutes before, 1 good minute after "now"
df["valve7"] = numpy.where( (before>=7*60) & (after>=60), vv, bad )

num_data_cols = df.iloc[0,4]
num_meta_cols = df.iloc[0,5]

data_cols = df.columns[6:6+num_data_cols]
meta_cols = df.columns[6+num_data_cols:6+num_data_cols+num_meta_cols]

newdf = pandas.concat( [df[["datetime","station_name","instrument_name","num_calc_cols","num_data_cols","num_meta_cols"]],
                        df["valve2"],df["valve3"],df["valve5"],df["valve7"],df[data_cols],df[meta_cols]], axis=1 )
newdf["num_calc_cols"] = [4]*len(newdf)

newdf.set_index( "datetime" ).to_csv( outfile )

