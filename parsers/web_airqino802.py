import sys

import json
import pandas
import zoneinfo

infile = sys.argv[1]
outfile = sys.argv[2]

df = pandas.read_csv( infile, sep=';' )

#df["timestamp"] = pandas.to_datetime( df["bucket_start_timestamp"], format="%Y-%m-%d %H:%M:%S", utc=False ).dt.tz_localize(tz="Europe/Rome", ambiguous="NaT" )
df["datetime"] = pandas.to_datetime( df["bucket_start_timestamp"], format="%Y-%m-%d %H:%M:%S", utc=True )

df["station_name"] = ["Milan - Linate - CE"]*len(df)
df["instrument_name"] = ["Airqino WebAPI"]*len(df)
df["num_calc_cols"] = [0]*len(df)
df["num_data_cols"] = [1]*len(df)
df["num_meta_cols"] = [0]*len(df)

for meas in ["pm25"]:
    newdf = df.rename( columns={"raw_value": meas} ).set_index( "datetime" )
    newdf = newdf[newdf.sensor == meas][["station_name","instrument_name","num_calc_cols","num_data_cols","num_meta_cols",meas]]
    newdf.to_csv( f"{outfile}_{meas}.csv" )

    for idx in newdf.index:
        stn = newdf.loc[idx,"station_name"].replace(" ","\\ ")
        ins = newdf.loc[idx,"instrument_name"].replace(" ","\\ ")
        val = newdf.loc[idx,meas]
        print( f"pm,installation={stn},instrument={ins} {meas}={val} {int(1e9*idx.timestamp())}" )

for meas in ["co","no2"]:
    newdf = df.rename( columns={"raw_value": meas} ).set_index( "datetime" )
    newdf = newdf[newdf.sensor == meas][["station_name","instrument_name","num_calc_cols","num_data_cols","num_meta_cols",meas]]
    newdf.to_csv( f"{outfile}_{meas}.csv" )

    for idx in newdf.index:
        stn = newdf.loc[idx,"station_name"].replace(" ","\\ ")
        ins = newdf.loc[idx,"instrument_name"].replace(" ","\\ ")
        val = newdf.loc[idx,meas]
        print( f"noxco,installation={stn},instrument={ins} {meas}={val} {int(1e9*idx.timestamp())}" )

