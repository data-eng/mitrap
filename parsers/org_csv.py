import sys
import numpy
import pandas
import datetime

infilename = sys.argv[1]
station_name = sys.argv[2]
instrument_name = sys.argv[3]
csvfilename = sys.argv[4]
instrument_tz = sys.argv[5]

assert instrument_tz == "UTC"
df = pandas.read_csv( infilename, parse_dates=["datetime"] )

# Print out lp with "OM" only
stn = station_name.replace(" ","\\ ")
ins = instrument_name.replace(" ","\\ ")
for idx in df.index:
    print( f"org,installation={stn},instrument={ins} ppcc={df.loc[idx,'Org']} {df.loc[idx,'datetime'].value}" )

df.set_index("datetime").to_csv( csvfilename )

