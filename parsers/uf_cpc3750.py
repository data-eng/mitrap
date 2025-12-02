import sys
import pandas
import datetime

infile = sys.argv[1]
outfile = sys.argv[2]
installation = sys.argv[3]
instrument = sys.argv[4]

if len(sys.argv) > 5:
    instrument_tz = sys.argv[5]
else:
    instrument_tz = "UTC"

df = pandas.read_csv( infile, sep=" " )

if instrument_tz == "UTC":
    df["datetime"] = pandas.to_datetime( df["#date"]+" "+df["time"], format='%Y-%m-%d %H:%M:%S', utc=True )
else:
    df["datetime"] = pandas.to_datetime( df["#date"]+" "+df["time"], format='%Y-%m-%d %H:%M:%S', utc=False ).dt.tz_localize(tz = instrument_tz)

df.to_csv( outfile, sep="," )

installation = installation.replace(" ","\\ ")
instrument = instrument.replace(" ","\\ ")

for idx in df.index:
    print( f"uf,installation={installation},instrument={instrument} concentration_cc={df.loc[idx,'concentration[#/cm3]']} {df.loc[idx,'datetime'].value}" )


