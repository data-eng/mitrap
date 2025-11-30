import sys
import pandas

infile = sys.argv[1]
outfile = sys.argv[2]
station_name = sys.argv[3]
instrument_name = sys.argv[4]

if len(sys.argv) > 5:
    instrument_tz = sys.argv[5]
else:
    instrument_tz = "UTC"

df = pandas.read_csv( infile, names=["date","time","p_psi","PSI","p_pa","Pa","p_kpa","kPa","p_torr","torr","p_inhg","inHg","p_atm","atm","p_bar","bar","conc_3_percent","%3","conc_c3","C3","conc_5_percent","%5","conc_c5","C5","valve_state","valve"] )

if instrument_tz == "UTC":
    df["datetime"] = pandas.to_datetime( df["date"] + " " + df["time"], format='%Y-%m-%d %H:%M:%S', utc=True )
else:
    df["datetime"] = pandas.to_datetime( df["date"] + " " + df["time"], format='%Y-%m-%d %H:%M:%S', utc=False ).dt.tz_localize(tz = "Europe/Athens")

df = df.drop( ["date","time"], axis=1 ).set_index( 'datetime' )

boring_columns = ["Pa","kPa","torr","inHg","atm","bar","%3","C3","%5","C5","valve"]
for col in boring_columns:
    # todo: check all values equal to column name
    pass
df = df.drop( boring_columns, axis=1 )

df.to_csv( outfile )

installation = station_name.replace(" ","\\ ")
instrument = instrument_name.replace(" ","\\ ")
for idx in df.index:
    print( f"uf,installation={installation},instrument={instrument} valve={df.loc[idx,'valve_state']} {idx.value}" )
