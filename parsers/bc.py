import sys
import pandas
import numpy

infile = sys.argv[1]
outfile = sys.argv[2]
separator = sys.argv[3]
date_col = sys.argv[4]
time_col = sys.argv[5]
datetime_fmt = sys.argv[6]
instrument_tz = sys.argv[7]
measurement_col = sys.argv[8]
measurement_unt = sys.argv[9]

df = pandas.read_csv( infile, sep=separator )

if date_col == time_col:
    if instrument_tz == "UTC":
        df["datetime"] = pandas.to_datetime( df[date_col], format=datetime_fmt, utc=True )
    elif instrument_tz == "FILE":
        df["datetime"] = pandas.to_datetime( df[date_col], format=datetime_fmt, utc=False )
    else:
        df["datetime"] = pandas.to_datetime( df[date_col], format=datetime_fmt, utc=False ).dt.tz_localize( tz = instrument_tz, ambiguous='NaT' )
    df = df.drop( [date_col], axis=1 )

else:
    if instrument_tz == "UTC":
        df["datetime"] = pandas.to_datetime( df[date_col] + " " + df[time_col], format=datetime_fmt, utc=True )
    elif instrument_tz == "FILE":
        df["datetime"] = pandas.to_datetime( df[date_col] + " " + df[time_col], format=datetime_fmt, utc=False )
    else:
        df["datetime"] = pandas.to_datetime( df[date_col] + " " + df[time_col], format=datetime_fmt, utc=False ).dt.tz_localize( tz = instrument_tz, ambiguous='NaT' )
    df = df.drop( [date_col,time_col], axis=1 )
                

df["calc_cols"] = [1]*len(df)
df["data_cols"] = [df.shape[1]-1]*len(df) # -1 because some columns are dropped, cf below
df["meta_cols"] = [0]*len(df)
df["concentration_cc"] =  df[measurement_col] * float(measurement_unt)

# Apply unit conversion to make concentration_cc    
# Re-order so that "datetime" and "concentration_cc" are the first two columns.
# Drop the date, time fields that were used to make "datetime"

cols_infront = ["datetime","calc_cols","data_cols","meta_cols","concentration_cc"]
new_df = df[cols_infront]
new_df = pandas.concat( [new_df,df.drop(cols_infront,axis=1)], axis=1 )

# Drop the NaT rows
new_df = new_df[ new_df.datetime == new_df.datetime ]

new_df.to_csv( outfile, index=False )

