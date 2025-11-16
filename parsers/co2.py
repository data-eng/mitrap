import sys
import numpy
import pandas

df = pandas.read_csv( sys.argv[1], parse_dates=["Datetime"], index_col=False )

# This throws a warning that "Length of header or names does not match length of data."
# It happens that the file gets an extra column after some point, which is not named
# in the header. Since it is not a column of interest, it should be ok to ignore it.

df = df.dropna( axis=0 )
df["timestamp"] = df["Datetime"].apply( lambda d: d.value )

for i in df.index:

    print( f"co2,installation={sys.argv[2]},instrument={sys.argv[3]} value={df.loc[i,'CO2_ppm']} {df.loc[i,'timestamp']}" )

