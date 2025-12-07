import sys
import pandas
import numpy

infile = sys.argv[1]
outfile = sys.argv[2]
station_name = sys.argv[3]
instrument_name = sys.argv[4]
instrument_tz = sys.argv[5]

df = pandas.read_csv( infile, sep=' ' )

date_col = "#date"
time_col = "time"
datetime_fmt = "%Y-%m-%d %H:%M:%S"

if instrument_tz == "UTC":
    datetime = pandas.to_datetime( df[date_col] + " " + df[time_col], format=datetime_fmt, utc=True )
else:
    datetime = pandas.to_datetime( df[date_col] + " " + df[time_col], format=datetime_fmt, utc=False ).dt.tz_localize(tz = instrument_tz)

df.drop( [date_col,time_col], axis=1, inplace=True )
for c in ["daydec","day_dec","Timebase[s]"]:
    if c in df: df.drop( [c], axis=1, inplace=True )

stn_df = pandas.DataFrame( [station_name]*df.shape[0], columns=["station_name"] )
ins_df = pandas.DataFrame( [instrument_name]*df.shape[0], columns=["instrument_name"] )

new_df = pandas.concat( [datetime.to_frame(name="datetime"), stn_df, ins_df, df], axis=1 )
new_df.to_csv( outfile, index=False )
