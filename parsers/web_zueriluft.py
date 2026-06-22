import sys

import pandas
import zoneinfo

infile = sys.argv[1]
outfile = sys.argv[2]

df = pandas.read_csv( infile )

tzdk = zoneinfo.ZoneInfo("Europe/Zurich")
df["datetime"] = pandas.to_datetime( df["datetime"], utc=False ).dt.tz_localize(tz = "Europe/Zurich")
df["instrument"] = ["Zueriluft Server"]*len(df)

df = df[["datetime","instrument","station","variable","value","unit","error"]]
df = df[(df.error==0) & (df.value==df.value)]
df.to_csv( f"{outfile}.csv", index=None )

for idx in df.index:
    stn = df.loc[idx,"station"].replace(" ","\\ ")
    ins = df.loc[idx,"instrument"].replace(" ","\\ ")
    mea = df.loc[idx,"variable"]
    val = df.loc[idx,"value"]
    ts =  df.loc[idx,"datetime"].value
    print( f"noxco,installation={stn},instrument={ins} {mea}={val} {ts}" )

sys.exit(0)


