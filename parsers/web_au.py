import sys

import json
import pandas
import zoneinfo

infile = sys.argv[1]
outfile = sys.argv[2]
installation = sys.argv[3]
instrument = sys.argv[4]

with open( infile, "r" ) as fp:
    j = json.load( fp )

rows = []
for entry in j:
    for var in ["CO","NO2","NOx"]:
        rows.append( [entry["Recorded"],var,entry.get(var)] )
df = pandas.DataFrame( rows, columns=["datetime","variable","value"] )
df = df[df.value==df.value]
tzdk = zoneinfo.ZoneInfo("Europe/Copenhagen")
df["datetime"] = pandas.to_datetime( df["datetime"], utc=False ).dt.tz_localize(tz = "Europe/Copenhagen")
df["installation"] = [installation]*len(df)
df["instrument"] = [instrument]*len(df)
df = df[["datetime","installation","instrument","variable","value"]]
df = df.set_index("datetime").sort_index()
df.to_csv( outfile )

rows = []
for entry in j:
    rows.append( [entry["Recorded"],entry.get("CO"),entry.get("NO2"),entry.get("NOx")] )
df = pandas.DataFrame( rows, columns=["datetime","co","no2","nox"] )
df = df[df.co==df.co]
tzdk = zoneinfo.ZoneInfo("Europe/Copenhagen")
df["datetime"] = pandas.to_datetime( df["datetime"], utc=False ).dt.tz_localize(tz = "Europe/Copenhagen")
df = df.set_index("datetime").sort_index()
installation = installation.replace(" ","\\ ")
instrument = instrument.replace(" ","\\ ")

for idx in df[df.co==df.co].index:
    print( f"noxco,installation={installation},instrument={instrument} nox={df.loc[idx,'nox']},no2={df.loc[idx,'no2']},co={df.loc[idx,'co']} {idx.value}" )

