import sys
import pandas

infile = sys.argv[1]
outfile = sys.argv[2]
file_type = sys.argv[3]
station_name = sys.argv[4]
instrument_name = sys.argv[5]
instrument_tz = sys.argv[6]

if file_type == "1":
    df = pandas.read_csv( infile, names=["date","time","p_psi","PSI","p_pa","Pa","p_kpa","kPa","p_torr","torr","p_inhg","inHg","p_atm","atm","p_bar","bar","conc_3_percent","%3","conc_c3","C3","conc_5_percent","%5","conc_c5","C5","valve_state","valve"] )
    boring_columns = ["PSI","Pa","kPa","torr","inHg","atm","bar","%3","C3","%5","C5","valve"]
    if instrument_tz == "UTC":
        df["datetime"] = pandas.to_datetime( df["date"] + " " + df["time"], format='%Y-%m-%d %H:%M:%S', utc=True )
    else:
        df["datetime"] = pandas.to_datetime( df["date"] + " " + df["time"], format='%Y-%m-%d %H:%M:%S', utc=False ).dt.tz_localize( tz = instrument_tz, ambiguous='NaT' )
    df = df.drop( ["date","time"], axis=1 )

elif file_type == "2":
    df = pandas.read_csv( infile, names=["datetime1","p_psi","PSI","p_pa","Pa","p_kpa","kPa","p_torr","torr","p_inhg","inHg","p_atm","atm","p_bar","bar","conc_3_percent","%3","conc_c3","C3","conc_5_percent","%5","conc_c5","C5","valve_state","valve","fan_state","fan"] )
    boring_columns = ["PSI","Pa","kPa","torr","inHg","atm","bar","%3","C3","%5","C5","valve","fan"]
    if instrument_tz == "UTC":
        df["datetime"] = pandas.to_datetime( df["datetime1"], format='%Y-%m-%d %H:%M:%S', utc=True )
    else:
        df["datetime"] = pandas.to_datetime( df["datetime1"], format='%Y-%m-%d %H:%M:%S', utc=False ).dt.tz_localize( tz = instrument_tz, ambiguous='NaT' )
    df = df.drop( ["datetime1"], axis=1 )

elif file_type == "3":
    df = pandas.read_csv( infile, names=["datetime1","p_psi","PSI","p_pa","Pa","p_kpa","kPa","p_torr","torr","p_inhg","inHg","p_atm","atm","p_bar","bar","conc_3_percent","%3","conc_c3","C3","conc_5_percent","%5","conc_c5","C5","valve_state","valve"] )
    boring_columns = ["PSI","Pa","kPa","torr","inHg","atm","bar","%3","C3","%5","C5","valve"]
    if instrument_tz == "UTC":
        df["datetime"] = pandas.to_datetime( df["datetime1"], format='%Y-%m-%d %H:%M:%S', utc=True )
    else:
        df["datetime"] = pandas.to_datetime( df["datetime1"], format='%Y-%m-%d %H:%M:%S', utc=False ).dt.tz_localize( tz = instrument_tz, ambiguous='NaT' )
    df = df.drop( ["datetime1"], axis=1 )

elif file_type == "4":
    df = pandas.read_csv( infile, names=["datetime1","valve1"] )
    boring_columns = []
    if instrument_tz == "UTC":
        df["datetime"] = pandas.to_datetime( df["datetime1"], format='%d-%b-%Y %H:%M:%S', utc=True )
    else:
        df["datetime"] = pandas.to_datetime( df["datetime1"], format='%d-%b-%Y %H:%M:%S', utc=False ).dt.tz_localize( tz = instrument_tz, ambiguous='NaT' )
    df["valve_state"] = df.valve1.apply( lambda v: 0 if v=="CS" else 1 )
    df = df.drop( ["datetime1","valve1"], axis=1 )

else:
    df = None


for col in boring_columns:
    # todo: check all values equal to column name
    pass
df = df.drop( boring_columns, axis=1 )

dfv = df.drop( ["datetime"], axis=1 )
num_data_cols = len(dfv.columns)

dfmisc = pandas.DataFrame( [[station_name,instrument_name,0,num_data_cols,0]]*len(dfv),
                           columns=["station_name","instrument_name","num_calc_cols","num_data_cols","num_meta_cols"] ) 
newdf = pandas.concat( [df["datetime"],dfmisc,dfv], axis=1 )

# There shall be no duplicate datetimes
newdf.drop_duplicates( subset="datetime", keep="last", inplace=True )
# Drop the NaT rows
newdf = newdf[ newdf.datetime == newdf.datetime ]
newdf.set_index( "datetime" ).to_csv( outfile )

