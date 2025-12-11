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
    print( f"mpss,installation={stn},instrument={ins},valve={df.loc[idx,'valve_state']} {values} {df.loc[idx,'datetime'].value}" )
    print( f"mpss1,installation={stn},instrument={ins},valve={df.loc[idx,'valve_state_1']} {values} {df.loc[idx,'datetime'].value}" )
    print( f"mpss2,installation={stn},instrument={ins},valve={df.loc[idx,'valve_state_2']} {values} {df.loc[idx,'datetime'].value}" )
    print( f"mpss3,installation={stn},instrument={ins},valve={df.loc[idx,'valve_state_3']} {values} {df.loc[idx,'datetime'].value}" )
    print( f"mpss4,installation={stn},instrument={ins},valve={df.loc[idx,'valve_state_4']} {values} {df.loc[idx,'datetime'].value}" )

