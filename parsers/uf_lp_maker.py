import sys
import pandas
import numpy

infile = sys.argv[1]
installation = sys.argv[2]
instrument = sys.argv[3]

df = pandas.read_csv( infile, parse_dates=["datetime"] )

# There shall be no duplicate datetimes
before = len(df)
df.drop_duplicates( subset="datetime", keep="last", inplace=True )
dup = len(df)-before

df = df.set_index( "datetime" )

installation = installation.replace(" ","\\ ")
instrument = instrument.replace(" ","\\ ")
for idx in df.index:
    print( f"uf,installation={installation},instrument={instrument} concentration_cc={df.loc[idx,'concentration_cc']},valve_state={df.loc[idx,'valve_state']} {int(1e9*idx.timestamp())}" )


