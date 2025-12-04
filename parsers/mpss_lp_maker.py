import sys
import pandas
import numpy

infile = sys.argv[1]

df = pandas.read_csv( infile, parse_dates=["datetime"] )

installation = ""
instrument = ""

line = f"mpss "

col = []
for c in df.columns:
    if c.startswith( "nm_" ): col.append( c )

for idx in df.index:
    stn = df.loc[idx,"station_name"].replace(" ","\\ ")
    ins = df.loc[idx,"instrument_name"].replace(" ","\\ ")
    values = ""
    for c in col:
        if values == "": values = f"{c}={df.loc[idx,c]}"
        else: values += f",{c}={df.loc[idx,c]}"
    print( f"mpss,installation={stn},instrument={ins} {values} {df.loc[idx,'datetime'].value}" )

