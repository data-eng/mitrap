import sys
import pandas

infile = sys.argv[1]
outfile = sys.argv[2]
valvefile = sys.argv[3]

dfd = pandas.read_csv( infile, parse_dates=["datetime"] )
dfd["ts"] = pandas.DatetimeIndex( dfd.datetime.apply(lambda t: int(1e9*t.timestamp())) )

dfv = pandas.read_csv( valvefile, parse_dates=["datetime"] )
dfv["ts"] = pandas.DatetimeIndex( dfv.datetime.apply(lambda t: int(1e9*t.timestamp())) )
dfv = dfv.set_index("ts")

names_in =["valve_state","valve2","valve3","valve5","valve7"] 
names_out =["before","after","valve2","valve3","valve5","valve7"] 

def valve_finder( datetime, dfv, names ):

    valve_before = dfv.index.get_indexer( [datetime], method="ffill" )
    t0 = dfv.index[valve_before]
    v0 = dfv.loc[t0,names]

    valve_after = dfv.index.get_indexer( [datetime], method="bfill" )
    t1 = dfv.index[valve_after]
    v1 = dfv.loc[t1,names]
    dt = (t1.astype(int)-t0.astype(int))/1e9
    #print(t0,t1,dt)

    retv = [v0.iloc[0,0],v1.iloc[0,0]]
    for i in range(1,5):
        if (v0.iloc[0,i]==2) or (v1.iloc[0,i]==2):
            # Invalid value on either end, means invalid
            v = 2
        elif v0.iloc[0,i] == v1.iloc[0,i]:
            # Both ends agree
            v = v0.iloc[0,i]
        else:
            # 0->1 or 1->0 should never happen,
            # there should always be a 2 between them
            # But it can happen in edge cases of valve2, as the 
            # safety margin is too short.
            v = 2
            assert i==0
        # This should never happen
        # If there is a gap, there should a 2
        if v != 2 and dt>70:
            #assert 1==0
            print( f"ERROR {datetime}" )
            continue
        retv.append(v)

    return retv

vv = dfd["ts"].apply(valve_finder,args=[dfv,names_in]).tolist()
vv = pandas.DataFrame( vv, columns=names_out )

# CAREFUL: only for uf. Must be re-visited.
data = dfd["concentration_cc"]
dfd.drop( ["concentration_cc"], axis=1, inplace=True )
dfd["num_calc_cols"] = [0]*len(dfd)
dfd["num_data_cols"] = [1]*len(dfd)
dfd["num_meta_cols"] = [1]*len(dfd)
dfd["concentration_cc"] = data
newdf = pandas.concat( [dfd,vv], axis=1 )
newdf["valve_state"] = newdf["valve3"]
newdf.drop( ["ts","before","after","valve2","valve3","valve5","valve7"], axis=1, inplace=True )

newdf = newdf[ newdf["valve_state"] == newdf["valve_state"] ]
for col in ["num_calc_cols","num_data_cols","num_meta_cols","valve_state"]:
    newdf[col] = newdf[col].astype(int)

newdf.set_index( "datetime" ).to_csv( outfile )

