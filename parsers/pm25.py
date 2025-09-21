import sys
import numpy
import pandas


# 31 bin edges, diameters 
grimm_bin_edges = [0.25,0.28,0.3,0.35,0.4,0.45,0.5,0.58,0.65,0.7,0.8,1,1.3,1.6,2,2.5,3,3.5,4,5,6.5,7.5,8.5,10,12.5,15,17.5,20,25,30,32]

# 30 bin centers, geometric mean of the bin edges
grimm_bins = [0.2646,0.2898,0.324,0.3742,0.4243,0.4743,0.5385,
              0.614,0.6745,0.7483,0.8944,1.1402,1.4422,1.7889,2.2361,
              2.7386,3.2404,3.7417,4.4721,5.7009,6.9821,7.9844,9.2195,11.1803,13.6931,16.2019,18.7083,22.3607,27.3861,30.9839]

# The following factors out calculations over constants
# Calculate the volume for each bin as val * pi * diam^3 / 6
# Multiply by 1.6 (g/cm-3) density and divide by 10^3 to get μg/m3

df = pandas.read_csv( sys.argv[1], header=None )
if df.loc[0,2] == "grimm":
    constants = numpy.power( numpy.array(grimm_bins), 3 ) * numpy.pi / 6 * 1.6E-3
    l = len(constants)

# These must now be multiplied by the values (particle counts) in the data

v = numpy.array( df.drop([0,1,2],axis=1) )
m = v[:,0:l] * constants
pm25 = 2 * numpy.sum( m[:,0:7], axis=1 ) + numpy.sum( m[:,7:15], axis=1 )
df = df.drop( range(3,df.shape[1]), axis=1 )
df["pm25"] = pm25
