import sys
import pandas
import numpy

infile = sys.argv[1]
outfile = sys.argv[2]
date_col = sys.argv[3]
time_col = sys.argv[4]
datetime_fmt = sys.argv[5]
station_name = sys.argv[6]
instrument_name = sys.argv[7]
instrument_tz = sys.argv[8]

diameters = ["6.15","6.38", "6.61","6.85","7.10","7.37","7.64","7.91","8.20","8.51",
             "8.82","9.14","9.47","9.82",
             " 10.2"," 10.6"," 10.9"," 11.3"," 11.8"," 12.2"," 12.6"," 13.1",
             " 13.6"," 14.1"," 14.6"," 15.1"," 15.7"," 16.3"," 16.8"," 17.5",
             " 18.1"," 18.8"," 19.5"," 20.2"," 20.9"," 21.7"," 22.5"," 23.3",
             " 24.1"," 25.0"," 25.9"," 26.9"," 27.9"," 28.9"," 30.0"," 31.1",
             " 32.2"," 33.4"," 34.6"," 35.9"," 37.2"," 38.5"," 40.0"," 41.4",
             " 42.9"," 44.5"," 46.1"," 47.8"," 49.6"," 51.4"," 53.3"," 55.2",
             " 57.3"," 59.4"," 61.5"," 63.8"," 66.1"," 68.5"," 71.0"," 73.7",
             " 76.4"," 79.1"," 82.0"," 85.1"," 88.2"," 91.4"," 94.7"," 98.2",
             "101.8","105.5","109.4","113.4","117.6","121.9","126.3","131.0",
             "135.8","140.7","145.9","151.2","156.8","162.5","168.5","174.7",
             "181.1","187.7","194.6","201.7","209.1","216.7"]

df = pandas.read_csv( infile, low_memory=False )

bad_idx = []

stn = station_name.replace(" ","\\ ")
ins = instrument_name.replace(" ","\\ ")
line_prefix = f"smps_data,installation={stn},instrument={ins}"

for idx in df.index:
    try:
        dt = pandas.to_datetime( df.loc[idx,date_col] + " " + df.loc[idx,time_col], format=datetime_fmt, utc=True )
        #dt = utc=False ).dt.tz_localize( tz = instrument_tz, ambiguous='NaT' )
    except:
        bad_idx.append( f"BAD: {idx} {df.loc[idx,date_col]} {df.loc[idx,time_col]}" )
        dt = None
        continue

    line = ""
    for d in diameters:
        field_name = f"nm{d}".replace( ".", "_" ).replace( " ", "" )
        if line == "": line = f"{field_name}={df.loc[idx,d]}"
        else: line += f",{field_name}={df.loc[idx,d]}"
        
    print( f"{line_prefix} {line} {dt.value}" )

#print(bad_idx)
