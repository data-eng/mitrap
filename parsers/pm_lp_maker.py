import sys
import pandas
import numpy

infile = sys.argv[1]

df = pandas.read_csv( infile, parse_dates=["datetime"] )

for idx in df.index:
    stn = df.loc[idx,"station_name"].replace(" ","\\ ")
    ins = df.loc[idx,"instrument_name"].replace(" ","\\ ")

    print( f"pm,installation={stn},instrument={ins} pm25={1.6*df.loc[idx,'cycl_vol[m3]']} {df.loc[idx,'datetime'].value}" )

