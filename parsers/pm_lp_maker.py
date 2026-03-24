import sys
import pandas
import numpy

infile = sys.argv[1]

df = pandas.read_csv( infile, parse_dates=["datetime"] )

# There shall be no duplicate datetimes
before = len(df)
df.drop_duplicates( subset="datetime", keep="last", inplace=True )
dup = len(df)-before

df = df.set_index( "datetime" )

for idx in df.index:
    stn = df.loc[idx,"station_name"].replace(" ","\\ ")
    ins = df.loc[idx,"instrument_name"].replace(" ","\\ ")
    if "pm25" in df.columns:
        meas = df.loc[idx,"pm25"]
    elif "per_conc[ug/m3]" in df.columns:
        meas = df.loc[idx,"per_conc[ug/m3]"]
    else:
        meas = 1.6*df.loc[idx,"cycl_vol[m3]"]
    print( f"pm,installation={stn},instrument={ins} pm25={meas} {int(1e9*idx.timestamp())}" )

