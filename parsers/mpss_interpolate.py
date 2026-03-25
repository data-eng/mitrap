import sys
import pandas 
import numpy

infile = sys.argv[1]
outfile = sys.argv[2]

df = pandas.read_csv( infile )

# Target diameters

# mitrap006 diams
target_diam = numpy.array( [9.824,11.848,13.428,15.223,17.263,19.584,22.226,25.237,28.672,32.595,37.084,42.228,48.137,54.94,62.795,71.895,82.478,94.843,109.365,126.521,146.929,171.387,200.941,236.958,281.232,307.184] )

DeltalnD = numpy.median(numpy.log10(target_diam[1:]/target_diam[:-1]))

# Find where to read CSV shape
data_col_pos = df.columns.to_list().index("data_cols")
meta_col_pos = df.columns.to_list().index("meta_cols")
assert data_col_pos == 4
assert meta_col_pos == 5

num_data_cols = df.iloc[0,data_col_pos]
data_cols = [i for i in range(meta_col_pos+1,meta_col_pos+num_data_cols+1)]

head = df.columns.to_list()[meta_col_pos+1:meta_col_pos+num_data_cols+1]
diam = numpy.array( [float(d.replace("_",".").replace("nm","")) for d in head] )
data = df.values[:,meta_col_pos+1:meta_col_pos+num_data_cols+1].astype(float)

DeltalnDb = numpy.median(numpy.log10(diam[1:]/diam[:-1]))

interp_data = []
interp_err = []

for i in range(data.shape[0]):
    intp = numpy.interp(target_diam, diam, data[i,:])
    interp_data.append( intp )
    rel_err = (numpy.sum(intp*DeltalnD)-numpy.sum(data[i,:]*DeltalnDb)) / numpy.sum(data[i,:]*DeltalnDb)
    interp_err.append( rel_err )
     
df_calc= pandas.DataFrame( interp_data,columns=["interp_nm"+str(d).replace(".","_") for d in target_diam] )
df_err = pandas.DataFrame( interp_err, columns=["inter_err"] )

preamble = ["datetime","station_name","instrument_name","calc_cols","data_cols","meta_cols"]
df_old_data = df.drop( preamble, axis=1 )
df_preamble = df[ preamble ]

newdf = pandas.concat( [df[preamble],df_calc,df_old_data,df_err], axis=1 )
newdf["calc_cols"] = [len(target_diam)]*newdf.shape[0]
newdf["meta_cols"] = df["meta_cols"].apply( lambda n: n+1 )

newdf.to_csv( outfile, index=False )

#import matplotlib.pyplot as plt
#plt.plot(a_diam, y, b_diam, b_inv,'r')
#plt.show()

