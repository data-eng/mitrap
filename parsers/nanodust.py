import sys
import numpy
import pandas

df = pandas.read_csv( sys.argv[1], parse_dates=["Time_PC"] )

df = df[ ["Time_PC", "MODE", "PN"] ]
df = df.dropna( axis=0 )
df = df[ (df["MODE"]=="SPN") | (df["MODE"]=="TPN") ]
df["timestamp"] = df["Time_PC"].apply( lambda d: d.value )

for i in df.index:
    print( f"a {df.loc[i,'MODE']} b {df.loc[i,'PN']} c {df.loc[i,'timestamp']}" )









