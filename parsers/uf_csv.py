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
index_col = sys.argv[9]

if index_col != "no_index" and separator != ',':
    df = pandas.read_csv( infile, index_col=index_col, sep=separator )
elif index_col != "no_index"
    df = pandas.read_csv( infile, index_col=index_col )
elif separator != ',':
    df = pandas.read_csv( infile, sep=separator )
else:
    df = pandas.read_csv( infile )

if date_col == time_col:
    if instrument_tz == "UTC":
        df["datetime"] = pandas.to_datetime( df[date_col], format=datetime_fmt, utc=True )
    elif instrument_tz == "FILE":
        df["datetime"] = pandas.to_datetime( df[date_col], format=datetime_fmt, utc=False )
    else:
        df["datetime"] = pandas.to_datetime( df[date_col], format=datetime_fmt, utc=False )
    df = df.drop( [date_col], axis=1 )

else:
    if instrument_tz == "UTC":
        df["datetime"] = pandas.to_datetime( df[date_col] + " " + df[time_col], format=datetime_fmt, utc=True )
    elif instrument_tz == "FILE":
        df["datetime"] = pandas.to_datetime( df[date_col] + " " + df[time_col], format=datetime_fmt, utc=False )
    else:
        df["datetime"] = pandas.to_datetime( df[date_col] + " " + df[time_col], format=datetime_fmt, utc=False )
    df = df.drop( [date_col,time_col], axis=1 )
                
    
# Re-order so that "datetime" and "concentration_cc" are the first two columns.
# Drop the date, time fields that were used to make "datetime"

new_df = df[["datetime"]]
new_df["concentration_cc"] = df[measurement_col]
new_df = pandas.concat( [new_df,df.drop(["datetime",measurement_col],axis=1)], axis=1 )

new_df.to_csv( outfile, index=False )

