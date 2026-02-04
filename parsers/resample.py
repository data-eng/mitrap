import sys
import pandas

df = pandas.read_csv( sys.argv[1], parse_dates=["datetime"] ).set_index( "datetime" )
df1= df.resample("1min").agg("mean")
df1.to_csv( sys.argv[2] )

