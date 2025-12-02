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

# Re-order so that "datetime" and "concentration_cc" are the first two columns.
# Drop the date, time fields that were used to make "datetime"

new_df = df[ ["datetime"] ]
new_df["concentration_cc"] = df["concentration[#/cm3]"]
new_df = pandas.concat( [new_df,df.drop(["#date","time","datetime","concentration[#/cm3]"],axis=1)], axis=1 )

new_df.to_csv( outfile, sep=",", index=False )

