import sys
import datetime
import pandas


def func15min( dt ):
    if dt.minute < 15:
        retv = dt.replace(minute=15, second=0, microsecond=0)
    elif dt.minute < 30:
        retv = dt.replace(minute=30, second=0, microsecond=0)
    elif dt.minute < 45:
        retv = dt.replace(minute=45, second=0, microsecond=0)
    else:
        retv = dt.replace(minute=0, second=0, microsecond=0)
        retv += datetime.timedelta(hours=1)
    return retv

def func6h( dt ):
    if dt.hour < 6:
        retv = dt.replace(hour=6, minute=0, second=0, microsecond=0)
    if dt.hour < 12:
        retv = dt.replace(hour=12, minute=0, second=0, microsecond=0)
    if dt.hour < 18:
        retv = dt.replace(hour=18, minute=0, second=0, microsecond=0)
    else:
        retv = dt.replace(hour=0, minute=0, second=0, microsecond=0)
        retv += datetime.timedelta(days=1)

def func1d( dt ):
    retv = dt.replace(hour=0, minute=0, second=0, microsecond=0)
    retv += datetime.timedelta(days=1)
    return retv

aggr = {
        "15m": func15min,
        "6h": func6h
        }

df_all = pandas.read_csv( f"{sys.argv[1]}.csv", parse_dates=["datetime"] )
st = df_all.loc[0,"station_name"]
ins = df_all.loc[0,"instrument_name"]
st_lp = st.replace(" ","\\ ")
ins_lp = ins.replace(" ","\\ ")

df_all = pandas.read_csv( f"{sys.argv[1]}.csv", parse_dates=["datetime"] )
for i in df_all.index:
    print( f"pm,installation={st_lp},instrument={ins_lp},freq=1 pm25={df.loc[i,'pm25']} {df.loc[i,'datetime'].value}" )

for k in ["15m","6h"]: # Must be in order of inc aggregation
    #print( f"Aggregating to {k}. Starting with {len(df)} rows" )
    df["key"] = df["datetime"].apply(aggr[k])
    df = df[["key","pm25"]].groupby("key").agg(["mean","count"]).reset_index()
    #print( f"Aggregated to {len(df)} rows" )
    df.columns=["datetime","pm25","count"]
    limit = 0.5 * max(df["count"])
    df = df[ df["count"]>limit ].reset_index()
    #print( f"Filtered to {len(df)} rows" )
    dfother = pandas.DataFrame([[st,ins,1,0]]*len(df), columns=['station_name', 'instrument_name', 'num_data_col', 'num_meta_col'])
    df = pandas.concat( [df["datetime"],dfother,df["pm25"].round(3)], axis=1 )

    elif k == "15m": freq = 15*60
    elif k == "6h": freq = 6*60*60
    else: assert 1 ==0

    for i in df.index:
        print( f"pm,installation={st_lp},instrument={ins_lp},freq={freq} pm25={df.loc[i,'pm25']} {df.loc[i,'datetime'].value}" )

    df.set_index( "datetime" ).to_csv( f"{sys.argv[1]}_{k}.csv" )

