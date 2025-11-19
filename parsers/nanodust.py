import sys
import numpy
import pandas

df = pandas.read_csv( sys.argv[1], parse_dates=["Time_PC"], index_col=False )

# This throws a warning that "Length of header or names does not match length of data."
# It happens that the file gets an extra column after some point, which is not named
# in the header. Since it is not a column of interest, it should be ok to ignore it.

df = df[ ["Time_PC", "MODE", "PN"] ]
df = df.dropna( axis=0 )
df = df[ (df["MODE"]=="SPN") | (df["MODE"]=="TPN") ]
df["timestamp"] = df["Time_PC"].apply( lambda d: d.value )

for i in df.index:

    print( f"nanodust,installation={sys.argv[2]},instrument={sys.argv[3]} mode=\"{df.loc[i,'MODE']}\",pn={df.loc[i,'PN']},gmd=0.0 {df.loc[i,'timestamp']}" )

