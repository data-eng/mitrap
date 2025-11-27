import sys

import tomllib

import xml.dom.minidom
import pandas
import zoneinfo

infile = sys.argv[1]
outfile = sys.argv[2]

try:
    configfile = sys.argv[3]
except:
    configfile = "/mnt/installations.toml"
     
with open( configfile, "rb" ) as fp:
    config = tomllib.load( fp )

tzath = zoneinfo.ZoneInfo("Europe/Athens")

ignore_attr = ["datetime", "station_id", "station_name", "longitude", "latitude"]

dom = xml.dom.minidom.parse( infile )
rows = []
for el in dom.getElementsByTagName( "z:row" ):
    datetime = el.attributes["datetime"].value
    stationid = el.attributes["station_id"].value
    for (name,value) in el.attributes.items():
        if name not in ignore_attr:
            rows.append( [datetime, stationid, name, value] )
df = pandas.DataFrame( rows, columns=["datetime","station","variable","value"] )

df["datetime"] = df["datetime"].apply( lambda x: pandas.to_datetime(x) ).apply( lambda x: x.replace(tzinfo=tzath) )
df["timestamp"] = df["datetime"].apply( lambda x: x.timestamp() ).apply(int)

nowstamp = df.loc[df.index[-1],"timestamp"]

for k in config.keys():
    try:
        ypen = config[k]["ypen"]
        name = config[k]["city"].replace( ' ', '\\ ' )
    except:
        pass
    d = df[ (df["timestamp"]==nowstamp) & (df["station"]==ypen) ]
    if len(d) > 0:
        idx = d.index[0]
        print( f"noxco,installation={name},instrument=ypen nox={d.loc[idx,'nox']},no2={d.loc[idx,'no2']},co={d.loc[idx,'co']} {nowstamp}" )

