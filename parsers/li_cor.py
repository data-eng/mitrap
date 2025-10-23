import sys
import pandas
import datetime

df = pandas.read_csv( sys.argv[1], sep=' ' )
df["datetime"] = df['Date']+" "+df["Time(H:M:S)"]
df["timestamp"] = df["datetime"].apply( datetime.datetime.strptime, args=["%Y-%m-%d %H:%M:%S"] ).apply( lambda d: d.value )

df = df[['timestamp', 'datetime', 'CO2(ppm)', 'CellTemp(c)', 'CellPres(kPa)']]

df.to_csv( sys.argv[2], sep=',', index=False )
