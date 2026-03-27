import sys
import pandas
import numpy

infile = sys.argv[1]

df = pandas.read_csv( infile, parse_dates=["datetime"] )

# Optionally parameterize measurement name to create
# different re-binning scenarios
try: meas = sys.argv[2]
except: meas = "mpss"

col = []
for c in df.columns:
    if c.startswith( "interp_nm" ): col.append( c )

for idx in df.index:
    stn = df.loc[idx,"station_name"].replace(" ","\\ ")
    ins = df.loc[idx,"instrument_name"].replace(" ","\\ ")

    values = ""
    for c in col:
        val_name = c.replace("interp_","")
        if values == "": values = f"{val_name}={df.loc[idx,c]}"
        else: values += f",{val_name}={df.loc[idx,c]}"
    print( f"{meas},installation={stn},instrument={ins},valve={df.loc[idx,'valve_state']} {values} {df.loc[idx,'datetime'].value}" )

