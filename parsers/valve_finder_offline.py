import sys
import pandas
import numpy

infile_measurement = sys.argv[1]
infile_valve_state = sys.argv[2]
outfile = sys.argv[3]


df = pandas.read_csv( infile, index_col="Sample #" )

##
## DOES NOT WORK, WIP
##


# Find the valve timepoints that box this timepoint

def helper( t1, t2 ):
    if t1 > t2: return numpy.nan
    else: return t2.value - t1.value
def box( idx ):
    t1 = min( df_valve.index, key=lambda x: helper(df_valve.loc[x,"datetime"],df.loc[idx,"datetime"]))
    if t1 != t1:
        # There is nothing to the left
        return None,None,None,None
    t2 = t1+1
    if t2 < len(df_valve):
        #return t1,df_valve.loc[t1,"datetime"],df_valve.loc[t1,"valve_state"],t2,df_valve.loc[t2,"datetime"],df_valve.loc[t2,"valve_state"]
        return df_valve.loc[t1,"datetime"].value,df_valve.loc[t1,"valve_state"],df_valve.loc[t2,"datetime"].value,df_valve.loc[t2,"valve_state"]
    else:
        # The very last datapoint
        return df_valve.loc[t1,"datetime"].value,df_valve.loc[t1,"valve_state"],df_valve.loc[t1,"datetime"].value,df_valve.loc[t1,"valve_state"]

def valve_frac( idx ):
    t1,v1,t2,v2 = box( idx )
    # There is nothing to the left
    if v1!=v1: retv == None
    # Avoid unnecessary calculations for most timepoints
    # and also avoid the division by zero at the last timepoint
    elif v1==v2: retv = v1
    else:
        p1 = float(df.loc[idx,"datetime"].value - t1) / (t2-t1)
        p2 = float(t2 - df.loc[idx,"datetime"].value) / (t2-t1)
        retv = p1*v1 + p2*v2
    return retv

# We only provide the valve dataframe for off-line analytics.
# For real-time viz, we use flux to find the valve fraction.
if df_valve is not None:
    df["valve_frac"] = df.index.to_series().apply(valve_frac)


