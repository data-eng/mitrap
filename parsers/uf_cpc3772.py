import sys
import pandas

infile = sys.argv[1]
outfile = sys.argv[2]
installation = sys.argv[3]
instrument = sys.argv[4]

df = pandas.read_csv( infile, index_col="Sample #" )

df["datetime"] = pandas.to_datetime( df["Start Date"] + " " + df["Start Time"], format='%m/%d/%y %H:%M:%S', utc=False ).dt.tz_localize(tz = "Europe/Athens")

df = df.drop( ["Start Date","Start Time"], axis=1 )

df.to_csv( outfile )

installation = installation.replace(" ","\\ ")
instrument = instrument.replace(" ","\\ ")
for idx in df.index:
    print( f"uf,installation={installation},instrument={instrument} conc={df.loc[idx,'Conc Mean']} {df.loc[idx,'datetime']}" )
