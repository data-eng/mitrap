import numpy
import pandas

# 31 bin edges, diameters 
bin_edges = [0.25,0.28,0.3,0.35,0.4,0.45,0.5,0.58,0.65,0.7,0.8,1,1.3,1.6,2,2.5,3,3.5,4,5,6.5,7.5,8.5,10,12.5,15,17.5,20,25,30,32]

# 30 bin centers, geometric mean of the bin edges
bins = [0.2646,0.2898,0.324,0.3742,0.4243,0.4743,0.5385,
        0.614,0.6745,0.7483,0.8944,1.1402,1.4422,1.7889,2.2361,
        2.7386,3.2404,3.7417,4.4721,5.7009,6.9821,7.9844,9.2195,11.1803,13.6931,16.2019,18.7083,22.3607,27.3861,30.9839]

# The following factors out calculations over constants
# Calculate the volume for each bin as val * pi * diam^3 / 6
vol = numpy.power( numpy.array(bins), 3 ) * numpy.pi / 6
# Multiply by 1.6 (g/cm-3) density and divide by 10^3 to get μg/m3
den = vol * 1.6E-3
# den must now be multiplied by the values (particle counts) in the data


# Each timepoint k is five lines.
# line k+0 must start with P and is the time representation
# line k+1 must start with C_: Columns 1-8 are values for bins 0-7 
# line k+2 must start with C_; Columns 1-8 are values for bins 8-15 
# line k+3 must start with c_: and column 9 must be 160. Columns 1-8 are values for bins 16-23
# line k+4 must start with c_; Columns 1-6 are values for bins 24-29. Columns 7-8 must be zero

df = pandas.read_csv( "temp-aggregated-clean.csv", header=None )

# separate the date representation from the values

assert len(df) % 5 == 0
val = numpy.zeros( (32), dtype=numpy.float64 )

for idx in df.index:
    if idx % 5 == 0:
        if (df.loc[idx,0] != "P") or (df.loc[idx,6] != 1):
            print( f"This should never happen, {idx}" )
        else:
            y = df.loc[idx,1] + 2000
            m = df.loc[idx,2]
            d = df.loc[idx,3]
            hh = df.loc[idx,4]
            mm = df.loc[idx,5]
            datestr = f"{y}-{m}-{d} {hh:02}:{mm:02}"
        pm25 = 0
    elif idx % 5 == 1:
        if (df.loc[idx,0] != "C_:"):
            print( f"This should never happen, {idx}" )
        for i in range(7):
            pm25 += 2 * (df.loc[idx,i+1]-df.loc[idx,i+2]) * den[i]
            last = df.loc[idx,8]
    elif idx % 5 == 2:
        if (df.loc[idx,0] != "C_;"):
            print( f"This should never happen, {idx}, {df.loc[idx,0]} != C_;" )
        pm25 += (last - df.loc[idx,1]) * den[7]
        for i in range(7):
            pm25 += (df.loc[idx,i+1]-df.loc[idx,i+2]) * den[8+i]
        print( f"{datestr},{pm25}" )
    elif idx % 5 == 3:
        if (df.loc[idx,0] != "c_:"):
            print( f"This should never happen, {idx}, {df.loc[idx,0]} != c_:" )
    elif (idx % 5 == 4) and (df.loc[idx,0] != "c_;"):
        print( f"This should never happen, {idx}, {df.loc[idx,0]} != c_;" )
