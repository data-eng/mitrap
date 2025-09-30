import sys

import tomllib

import pandas
import zoneinfo


with open( "/mnt/installations.toml", "rb" ) as fp:
    config = tomllib.load( fp )

tzath = zoneinfo.ZoneInfo("Europe/Athens")
df = pandas.read_csv( sys.argv[1] )

df["datetime"] = df["datetime"].apply( lambda x: pandas.to_datetime(x) ).apply( lambda x: x.replace(tzinfo=tzath) )
df["timestamp"] = df["datetime"].apply( lambda x: x.timestamp() ).apply(int)
df["my_datetime"] = df["my_timestamp"].apply(int).apply(pandas.Timestamp,unit="s",tz="Europe/Athens")

#df.to_csv( sys.argv[1] + "1" )

#nowstamp = df["adj_timestamp"].max()
nowstamp = df.loc[df.index[-1],"timestamp"]

for k in config.keys():
    try:
        ypen = config[k]["ypen"]
        name = config[k]["city"].replace( ' ', '\ ' )
    except:
        pass
    d = df[ (df["timestamp"]==nowstamp) & (df["station"]==ypen) ]
    if len(d) > 0:
        idx = d.index[0]
        print( f"ypen,installation={name},instrument=ypen nox={d.loc[idx,'nox']},no2={d.loc[idx,'no2']},co={d.loc[idx,'co']} {nowstamp}" )

