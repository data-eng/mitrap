import sys
import pandas

infile = sys.argv[1]
outfile = sys.argv[2]
station_name = sys.argv[3]
instrument_name = sys.argv[4]
instrument_tz = sys.argv[5]
datetime_fmt = sys.argv[6]

df = pandas.read_csv( infile, sep='\t' )

date_col = "Time End"

if instrument_tz == "UTC":
    df["datetime"] = pandas.to_datetime( df[date_col], format=datetime_fmt, utc=True )
else:
    df["datetime"] = pandas.to_datetime( df[date_col], format=datetime_fmt, utc=False ).dt.tz_localize( tz = instrument_tz, ambiguous='NaT' )

data_cols_orig = ['10.27 nm', '13.94 nm', '18.97 nm', '25.87 nm', '35.41 nm', '48.72 nm', '67.56 nm', '94.77 nm', '135.26 nm', '197.97 nm', '300.00 nm'] 
data_cols_map = {}
for k in data_cols_orig:
    data_cols_map[k] = f"nm_{k.removesuffix(' nm').replace('.','_')}"
df = df.rename( data_cols_map, axis=1 )
data_cols = [data_cols_map[k] for f in data_cols_map]

# Type is alwyas "Dst", Cell P is always NaN.
# Scan # could be an index, but it sometimes starts with
# the last index from yesterday so it will just be confusing
meta_cols = ['Ext. T [°C]', 'Ext. RH [%]', 'Ext. 3 []', 'DMA P-nozzle [Pa]', 'DMA P [hPa]', 'DMA T [°C]']

df["station_name"] = [station_name]*len(df)
df["instrument_name"] = [instrument_name]*len(df)
df["calc_cols"] = [0]*len(df)
df["data_cols"] = [len(data_cols)]*len(df)
df["meta_cols"] = [len(meta_cols)]*len(df)

newdf_cols = ["datetime","station_name","instrument_name","calc_cols","data_cols","meta_cols"]
newdf_cols.extend( data_cols )
newdf_cols.extend( meta_cols )
newdf = df[ newdf_cols ]
newdf.to_csv( outfile, index=False )

