import sys
import datetime
import pandas


def func30sec( dt ):
    if dt.second < 30:
        retv = dt.replace(second=30, microsecond=0)
    else:
        retv = dt.replace(second=0, microsecond=0)
        retv += datetime.timedelta(minutes=1)
    return retv

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
    elif dt.hour < 12:
        retv = dt.replace(hour=12, minute=0, second=0, microsecond=0)
    elif dt.hour < 18:
        retv = dt.replace(hour=18, minute=0, second=0, microsecond=0)
    else:
        retv = dt.replace(hour=0, minute=0, second=0, microsecond=0)
        retv += datetime.timedelta(days=1)

def func12h( dt ):
    if dt.hour < 12:
        retv = dt.replace(hour=12, minute=0, second=0, microsecond=0)
    else:
        retv = dt.replace(hour=0, minute=0, second=0, microsecond=0)
        retv += datetime.timedelta(days=1)
    return retv

def func1d( dt ):
    retv = dt.replace(hour=0, minute=0, second=0, microsecond=0)
    retv += datetime.timedelta(days=1)
    return retv

def func10d( dt ):
    if dt.day < 10:
        retv = dt.replace(day=10, hour=0, minute=0, second=0, microsecond=0)
    elif dt.day < 20:
        retv = dt.replace(day=20, hour=0, minute=0, second=0, microsecond=0)
    else:
        retv = dt.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        retv += datetime.timedelta(months=1)
    return retv


aggr = {
        "30s": func30sec,
        "15m": func15min,
        "6h": func15min,
        "10d": func10d
        }

df_all = pandas.read_csv( f"{sys.argv[1]}.csv", parse_dates=["datetime"] )
st = df_all.loc[0,"station_name"]
ins = df_all.loc[0,"instrument_name"]
st_lp = st.replace(" ","\\ ")
ins_lp = ins.replace(" ","\\ ")

df = df_all.rename( columns={"co2":"CO2_ppm"} )
for i in df_all.index:
    print( f"co2,installation={st_lp},instrument={ins_lp},freq=1 co2_ppm={df.loc[i,'CO2_ppm']} {df.loc[i,'datetime'].value}" )

for k in ["30s","15m","6h"]: # Must be in order of inc aggregation
    #print( f"Aggregating to {k}. Starting with {len(df)} rows" )
    df["key"] = df["datetime"].apply(aggr[k])
    df = df[["key","CO2_ppm"]].groupby("key").agg(["mean","count"]).reset_index()
    #print( f"Aggregated to {len(df)} rows" )
    df.columns=["datetime","CO2_ppm","count"]
    limit = 0.5 * max(df["count"])
    df = df[ df["count"]>limit ].reset_index()
    #print( f"Filtered to {len(df)} rows" )
    dfother = pandas.DataFrame([[st,ins,1,0]]*len(df), columns=['station_name', 'instrument_name', 'num_data_col', 'num_meta_col'])
    df = pandas.concat( [df["datetime"],dfother,df["CO2_ppm"].round(1)], axis=1 )

    if k == "30s": freq = 30
    elif k == "15m": freq = 15*60
    elif k == "6h": freq = 6*60*60
    else: assert 1 ==0

    for i in df.index:
        print( f"co2,installation={st_lp},instrument={ins_lp},freq={freq} co2_ppm={df.loc[i,'CO2_ppm']} {df.loc[i,'datetime'].value}" )

    df.set_index( "datetime" ).to_csv( f"{sys.argv[1]}_{k}.csv" )

