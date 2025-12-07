import sys
import numpy
import pandas

df = pandas.read_csv( sys.argv[1], parse_dates=["Datetime"], index_col=False )

# This throws a warning that "Length of header or names does not match length of data."
# It happens that the file gets an extra column after some point, which is not named
# in the header. Since it is not a column of interest, it should be ok to ignore it.

df = df.dropna( axis=0 )

station_name = sys.argv[2]
station_name_lp = station_name.replace(" ","\\ ")

instr_name = sys.argv[3]
instr_name_lp = instr_name.replace(" ","\\ ")

for i in df.index:
    print( f"co2,installation={station_name_lp},instrument={instr_name_lp} value={df.loc[i,'CO2_ppm']} {df.loc[i,'Datetime'].value}" )

