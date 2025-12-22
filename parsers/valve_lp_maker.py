import sys
import pandas
import numpy

infile = sys.argv[1]

df = pandas.read_csv( infile, parse_dates=["datetime"] ).set_index( "datetime" )

for idx in df.index:
    stn = df.loc[idx,"station_name"].replace(" ","\\ ")
    ins = df.loc[idx,"instrument_name"].replace(" ","\\ ")
    print( f"valve,intallation={stn},instrument={ins} valve={df.loc[idx,'valve_state']} {idx.value}" )


