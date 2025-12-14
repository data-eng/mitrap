import sys
import datetime
import pandas

df = pandas.read_csv( sys.argv[1], parse_dates=["datetime"] ).set_index("datetime").sort_index()

df.to_csv("1.csv")

col_v = 4

# Just find the first starting point
i1 = 0
while i1 < df.shape[0] and df.index[i1].second != 0 and df.index[i1].second != 30:
    i1 += 1
end_t = df.index[i1]

rows = []

while i1 < df.shape[0]-1:
    aggr_v = 0.0
    aggr_n = 0
    i2 = i1
    end_t = end_t + datetime.timedelta(seconds=30)
    while i2 < df.shape[0]-1 and df.index[i2] < end_t:
        v = df.iloc[i1,col_v]
        if v == v:
            aggr_v += df.iloc[i1,col_v]
            aggr_n += 1
        i2 += 1
    if aggr_n > 15:
        rows.append( [end_t,aggr_v/aggr_n] )
        #print(f"{end_t} {aggr_v/aggr_n} {aggr_n} {df.index[i1]} ")
    i1 = i2

df2 = pandas.DataFrame(rows,columns=["datetime","co2"])

df_30sec = pandas.concat( [df2.datetime,pandas.DataFrame([[df.iloc[0,0],df.iloc[0,1],1,0]]*len(df2),columns=['station_name', 'instrument_name', 'num_data_col', 'num_meta_col']),df2.co2], axis=1 ).set_index("datetime")

df_30sec.to_csv("2.csv")

# Now aggregate to hours
i1 = 0
# The first end time is the end of the first hour
end_t = df_30sec.index[1650].replace(minute=0, second=0, microsecond=0) + datetime.timedelta(hours=1)

df_X = df_30sec.reset_index()
df_X["datehour"] = df_X.datetime.apply(lambda r: r.replace(minute=0,second=0,microsecond=0) + datetime.timedelta(hours=1) )
df_X["date"] = df_X.datehour.apply(lambda r: r.replace(hour=0) + datetime.timedelta(days=1) )
dfh = df_X[["co2","datehour"]].groupby("datehour").agg("mean")
dfd = df_X[["co2","date"]].groupby("datehour").agg("mean")



