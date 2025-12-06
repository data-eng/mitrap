import sys
import pandas
import numpy

infile = sys.argv[1]

df = pandas.read_csv( infile, parse_dates=["datetime"] )

for idx in df.index:
    stn = df.loc[idx,"station_name"].replace(" ","\\ ")
    ins = df.loc[idx,"instrument_name"].replace(" ","\\ ")

    print( f"aeth,installation={stn},instrument={ins} bc6={df.loc[idx,'BC6[ng/m3]']} {df.loc[idx,'datetime'].value}" )

