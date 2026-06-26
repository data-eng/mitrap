import sys

import json
import pandas
import zoneinfo

infile = sys.argv[1]
outfile = sys.argv[2]
station = sys.argv[3]

df = pandas.read_csv( infile, sep=';' )

#df["timestamp"] = pandas.to_datetime( df["bucket_start_timestamp"], format="%Y-%m-%d %H:%M:%S", utc=False ).dt.tz_localize(tz="Europe/Rome", ambiguous="NaT" )
df["datetime"] = pandas.to_datetime( df["bucket_start_timestamp"], format="%Y-%m-%d %H:%M:%S", utc=True )

if int(station) == 801:
    df["station_name"] = ["Milan - Senato - CE"]*len(df)
    measurements = ["pm25"]
elif int(station) == 802:
    df["station_name"] = ["Milan - Linate - CE"]*len(df)
    measurements = ["pm25","co","no2"]
else:
    print("Bad arg 3")
    sys.exit(-1)

df["instrument_name"] = ["Unknown"]*len(df)
df["num_calc_cols"] = [1]*len(df)
df["num_data_cols"] = [1]*len(df)
df["num_meta_cols"] = [0]*len(df)

for meas in measurements:
    raw_col = f"raw_{meas}"
    cal_col = f"calibrated_{meas}"
    newdf = df.rename( columns={"raw_value": raw_col, "calibrated_value":cal_col} ).set_index( "datetime" )
    newdf = newdf[newdf.sensor == meas][["station_name","instrument_name","num_calc_cols","num_data_cols","num_meta_cols",cal_col,raw_col]]
    newdf.to_csv( f"{outfile}_{meas}.csv" )

    influx_meas = "pm" if meas == "pm25" else "noxco"
    for idx in newdf.index:
        stn = newdf.loc[idx,"station_name"].replace(" ","\\ ")
        ins = newdf.loc[idx,"instrument_name"].replace(" ","\\ ")
        val = newdf.loc[idx,cal_col]
        print( f"{influx_meas},installation={stn},instrument={ins} {meas}={val} {int(1e9*idx.timestamp())}" )

