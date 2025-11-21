import sys
import numpy
import pandas
import datetime

infilename = sys.argv[1]
installation_name = sys.argv[2]
instrument_name = sys.argv[3]
csvfilename = sys.argv[4]

def read_itx_block( itx, header_line ):
    i = header_line + 1
    lines = []
    assert itx[i] == "BEGIN"
    i += 1
    while itx[i] != "END":
        lines.append( itx[i].split("\t") )
        i += 1
    arr = numpy.array( lines )
    n = i - header_line
            
    return arr, i


def read_itx( itx ):
    key = []
    values = []
    i = 0
    blocks = { "times": [], "values": [] }
    while i < len(itx) - 1:
        if itx[i].startswith( "WAVES" ):
            # Start a new block
            header = itx[i].split( "\t" )
            times = None
            values = None
            arr, end_line = read_itx_block( itx, i )
            if "acsm_local_time" in header[1:]:
                df_block = pandas.DataFrame( arr, columns=header )
                blocks["times"].append( df_block )
            elif "Org" in header[1:]:
                df_block = pandas.DataFrame( arr, columns=header )
                blocks["values"].append( df_block )
            i = end_line + 1
        else:
            i += 1
        #endif itx[i].startswith( "WAVES" )
    # end while i < len(itx) - 1
    return blocks

with open( infilename, "r" ) as f:
    itx = f.read().splitlines()

#print( f"Read {len(itx)} lines" )
assert itx[0] == "IGOR"
blocks = read_itx( itx )

# There must be exactly one of each of the two interesting blocks
# Their first column must be called "WAVES*". and is not interesting

assert len(blocks["times"]) == 1
waves = blocks["times"][0].columns[0]
assert waves.startswith( "WAVES" )
df1 = blocks["times"][0].drop( [waves], axis=1 )

assert len(blocks["values"]) == 1
waves = blocks["values"][0].columns[0]
assert waves.startswith( "WAVES" )
df2 = blocks["values"][0].drop( [waves], axis=1 )

# In IGOR files, time starts at 1904-01-01 00:00:00
# Both IGOR and numpy ignore leap seconds, so this should work
delta_sec = (numpy.datetime64("1970-01-01 00:00:00") - numpy.datetime64("1904-01-01 00:00:00")).astype(numpy.int64)
unix_timestamp = (df1["acsm_local_time"].apply(int) - delta_sec)
df0 = pandas.DataFrame( unix_timestamp.to_numpy(), columns=["timestamp"] )
df0["Datetime"] = df0["timestamp"].apply( datetime.datetime.utcfromtimestamp )
df0["Installation"] = [installation_name] * len(df0)
df0["Instrument"] = [instrument_name] * len(df0)

# time appears twice, "acsm_utc_time" and "acsm_local_time"
# TODO: they should be identical, check
df1 = df1.drop( ["acsm_utc_time","acsm_local_time"], axis=1 )

# Write out full CSV
df = pandas.concat( [df0,df1,df2], axis=1 ).set_index("timestamp")
df.to_csv( csvfilename )

# Print out lp with "Org" only
for idx in df.index:
    print( f"org ppcc={df.loc[idx,'Org']} {idx*1000}" )
    
