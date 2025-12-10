import sys
import numpy
import pandas

df = pandas.read_csv( sys.argv[1], index_col=False )

# This throws a warning that "Length of header or names does not match length of data."
# It happens that the file gets an extra column after some point, which is not named
# in the header. Since it is not a column of interest, it should be ok to ignore it.

df = df.dropna( axis=0 )

station_name = sys.argv[2]
station_name_lp = station_name.replace(" ","\\ ")

instr_name = sys.argv[3]
instr_name_lp = instr_name.replace(" ","\\ ")

instrument_tz = sys.argv[4]
datetime_fmt = sys.argv[5]

if instrument_tz == "UTC":
    df["datetime_tz"] = pandas.to_datetime( df["Datetime"], format=datetime_fmt, utc=True )
else:
    df["datetime_tz"] = pandas.to_datetime( df["Datetime"], format=datetime_fmt, utc=False ).dt.tz_localize(tz = instrument_tz)
df = df.drop( ["Datetime"], axis=1 )


for i in df.index:
    print( f"co2,installation={station_name_lp},instrument={instr_name_lp} value={df.loc[i,'CO2_ppm']} {df.loc[i,'datetime_tz'].value}" )

