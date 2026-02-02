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
        ypen = -1
        
    d = df[ (df["timestamp"]==nowstamp) & (df["station"]==str(ypen)) ]

    try:
        dd = d[ d["variable"]=="NOx" ]
        myline = f"nox={dd.iloc[0,3]}"
    except:
        myline = ""
    try:
        dd = d[ d["variable"]=="NO2" ]
        if len(myline) > 0: myline += ","
        myline += f"no2={dd.iloc[0,3]}"
    except:
        pass
    try:
        dd = d[ d["variable"]=="CO" ]
        if len(myline) > 0: myline += ","
        myline += f"co={dd.iloc[0,3]}"
    except:
        pass
    if len(myline) > 0:
        print( f"noxco,installation={name},instrument=ypen {myline} {nowstamp}" )

