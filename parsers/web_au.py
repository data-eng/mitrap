import sys

import json
import pandas
import zoneinfo

infile = sys.argv[1]
outfile = sys.argv[2]
station = sys.argv[3]

with open( infile, "r" ) as fp:
    j = json.load( fp )

rows = []
for entry in j:
    for var in entry:
        if var != "Recorded":
            rows.append( [entry["Recorded"],var,entry.get(var)] )
df = pandas.DataFrame( rows, columns=["datetime","variable","value"] )
df = df[df.value==df.value]
tzdk = zoneinfo.ZoneInfo("Europe/Copenhagen")
df["datetime"] = pandas.to_datetime( df["datetime"], utc=False ).dt.tz_localize(tz = "Europe/Copenhagen")
df["station"] = [station]*len(df)
df["instrument"] = ["AU WebAPI"]*len(df)
df = df[["datetime","instrument","station","variable","value"]]
df = df.set_index("datetime").sort_index()
df.to_csv( outfile )

# We want to wtite to influx:
# AARH3, all variables, to Aarhus
# JAGT1, NOx, NO2 to Copenhagen HR
# HCAB, CO to Copenhagen HR
# HVID, NOx, NO2 to Copenhagen CE
# HCØ, CO, to Copenhagen CE

whoiswho = {
    "AARH3": { "vars": ["NOx","NO2","CO"],
               "installation": "Aarhus - CE" },
    "JAGT1": { "vars": ["NOx","NO2"],
               "installation": "Copenhagen - HR" },
    "HCAB": { "vars": ["CO"],
               "installation": "Copenhagen - HR" },
    "HVID": { "vars": ["NOx","NO2"],
               "installation": "Copenhagen - CE" },
    "HCØ": { "vars": ["CO"],
               "installation": "Copenhagen - CE" }
}

installation = whoiswho[station]["installation"].replace( ' ', '\\ ' )
instrument = "AU WebAPI".replace( ' ', '\\ ' )
for var in whoiswho[station]["vars"]:
    dfx = df[ df["variable"]==var ]
    for idx in dfx.index:
        print( f"noxco,installation={installation},instrument={instrument} {var.lower()}={dfx.loc[idx,'value']} {idx.value}" )

