import sys
import pandas
import datetime

df = pandas.read_csv( sys.argv[1], sep=' ', header=None, names=["Time","CO2_ppm","Temperature_C","Press_kPa"] )

header_date = sys.argv[2]
header_hour = sys.argv[3]
num_days = int( sys.argv[4] )
savepath  = sys.argv[5]

# This file has a date, hour in the first line, and then only gives hours.
# Hours might roll over midnight, implicitly advancing the date

start_date = datetime.datetime.fromisoformat( header_date )
current_date = start_date
prev_time = datetime.time.fromisoformat( header_hour )

for idx in df.index:
    current_time = datetime.time.fromisoformat( df.loc[idx,"Time"] )
    if current_time < prev_time:
        num_days += 1
        current_date = current_date + datetime.timedelta(days=1)
    prev_time = current_time
    df.loc[idx,"Datetime"] = datetime.datetime.combine( current_date, current_time )

df = df[ ["Datetime","CO2_ppm","Temperature_C","Press_kPa"] ]
df.to_csv( savepath, sep=',', index=False )
sys.exit( num_days )
