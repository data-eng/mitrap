import sys

import json
import pandas
import zoneinfo

infile = sys.argv[1]
outfile = sys.argv[2]

with open( infile, "r" ) as fp:
    j = json.load( fp )

mapping = {
        "5827": { "measurement": "co", "station": "Milan - Marche - HR" },
        "5504": { "measurement": "no2", "station": "Milan - Marche - HR" },
        "6328": { "measurement": "nox", "station": "Milan - Marche - HR" },
        "5834": { "measurement": "co", "station": "Milan - Senato - CE" },
        "5551": { "measurement": "no2", "station": "Milan - Senato - CE" },
        "6354": { "measurement": "nox", "station": "Milan - Senato - CE" },
}

rows = []
for entry in j:
    if entry["stato"] == "VA":
        meas= mapping[entry["idsensore"]]["measurement"] 
        stn = mapping[entry["idsensore"]]["station"] 
        rows.append( [entry["data"],stn,meas,entry["valore"]] )
df = pandas.DataFrame( rows, columns=["datetime","station","measurement","value"] )

df = df[df.value==df.value]
if len(df) == 0: sys.exit(1)

tzdk = zoneinfo.ZoneInfo("Europe/Rome")
df["datetime"] = pandas.to_datetime( df["datetime"], utc=False ).dt.tz_localize(tz = "Europe/Rome")
df["instrument"] = ["Lombardia WebAPI"]*len(df)

df = df[["datetime","instrument","station","measurement","value"]]
df.to_csv( outfile )

for idx in df.index:
    stn = df.loc[idx,"station"].replace(" ","\\ ")
    ins = df.loc[idx,"instrument"].replace(" ","\\ ")
    mea = df.loc[idx,"measurement"]
    val = df.loc[idx,"value"]
    ts = df.loc[idx,"datetime"].value
    print( f"noxco,installation={stn},instrument={ins} {mea}={val} {ts}" )

sys.exit(0)

