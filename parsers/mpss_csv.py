import sys

import datetime
import pytz

import pandas
import numpy


infile = sys.argv[1]
outfile = sys.argv[2]
station_name = sys.argv[3]
instrument_name = sys.argv[4]

df = pandas.read_csv( infile, sep='\t' )

diameters = ["1.02","1.06","1.09","1.13","1.18","1.22","1.26","1.31","1.36","1.41","1.46","1.51","1.57","1.63","1.68","1.75","1.81","1.88","1.95","2.02","2.09","2.17","2.25","2.33","2.41","2.50","2.59","2.69","2.79","2.89","3.00","3.11","3.22","3.34","3.46","3.59","3.72","3.85","4.00","4.14","4.29","4.45","4.61","4.78","4.96","5.14","5.33","5.52","5.73","5.94","6.15","6.38","6.61","6.85","7.10","7.37","7.64","7.91","8.20","8.51","8.82","9.14","9.47","9.82"," 10.2"," 10.6"," 10.9"," 11.3"," 11.8"," 12.2"," 12.6"," 13.1"," 13.6"," 14.1"," 14.6"," 15.1"," 15.7"," 16.3"," 16.8"," 17.5"," 18.1"," 18.8"," 19.5"," 20.2"," 20.9"," 21.7"," 22.5"," 23.3"," 24.1"," 25.0"," 25.9"," 26.9"," 27.9"," 28.9"," 30.0"," 31.1"," 32.2"," 33.4"," 34.6"," 35.9"," 37.2"," 38.5"," 40.0"," 41.4"," 42.9"," 44.5"," 46.1"," 47.8"," 49.6"," 51.4"," 53.3"," 55.2"," 57.3"," 59.4"," 61.5"," 63.8"," 66.1"," 68.5"," 71.0"," 73.7"," 76.4"," 79.1"," 82.0"," 85.1"," 88.2"," 91.4"," 94.7"," 98.2","101.8","105.5","109.4","113.4","117.6","121.9","126.3","131.0","135.8","140.7","145.9","151.2","156.8","162.5","168.5","174.7","181.1","187.7","194.6","201.7","209.1","216.7","224.7","232.9","241.4","250.3","259.5","269.0","278.8","289.0","299.6","310.6","322.0","333.8","346.0","358.7","371.8","385.4","399.5","414.2","429.4","445.1","461.4","478.3","495.8","514.0","532.8","552.3","572.5","593.5","615.3","637.8","661.2","685.4","710.5","736.5","763.5","791.5","820.5","850.5","881.7","914.0","947.5","982.2"]

try:
    data_df = df[diameters]
except:
    data_df = None
    print( "ERROR: Strange diameters" )
    sys.exit( 1 )

# There is a copy of each diameter in the original files. These copies have
# identical column name and are not useful. pandas.read_csv() names these
# with a ".1" appended to the column name.

# Drop both the data and the ".1" columns from the original df
df = df.drop( diameters+[c + ".1" for c in diameters], axis=1 )

# Rename the columns so that names do not look like numbers
data_df.rename( (lambda c:"nm_"+c.strip()), axis=1, inplace=True )

# The original file is tab-separated with a gratuitous tab at the end of
# each file, which is read in as "Unnamed: 395". Drop it, while simultaneously
# checking for the correct number of columns

try:
    df = df.drop( ["Unnamed: 395"], axis=1 )
except:
    df = None
    print( "ERROR: Strange number of columns" )
    sys.exit( 1 )


# The timestamp is given as the decimal day offset from the start of the year.
# There are timestamps, so assume UTC.
# Throw away the fractions of seconds, they are an artfact of the representation.
def dec2iso( row ):
    return (datetime.datetime(int(row["Start Year"]), 1, 1) + datetime.timedelta(days=row["Start Date"])).replace(tzinfo=pytz.UTC).replace(microsecond=0)

datetime_series = df.apply( dec2iso, axis=1 )
datetime_df = pandas.DataFrame( datetime_series, columns=["datetime"] )

df = df.drop( ["Start Date", "End Date", "Start Year", "End Year"], axis=1 )

# The remaining columns (measurement metadata) should be:
# ["T-Sheath(K)","P-Sheath(hPa)","# of size bins", "Mean Free Path (m)", "Gas Viscosity (Pa*s)", "Sheath Flow R.H. (%)", "Neutralizer Status"]

num_cols = df.loc[:,"# of size bins"].unique()
if len(num_cols) != 1:
    print( "ERROR: \"# of size bins\" does not have one unique value" )
    sys.exit( 1 )
elif num_cols[0] != data_df.shape[1]:
    print( "ERROR: \"# of size bins\" does not agree with reality" )
    sys.exit( 1 )
df.drop( ["# of size bins"], axis=1, inplace=True )

data_width_df = pandas.DataFrame( [num_cols[0]]*data_df.shape[0], columns=["num_data_cols"] )
meta_width_df = pandas.DataFrame( [df.shape[1]]*data_df.shape[0], columns=["num_meta_cols"] )

station_df = pandas.DataFrame( [station_name]*data_df.shape[0], columns=["station_name"] )

instrument_df = pandas.DataFrame( [instrument_name]*data_df.shape[0], columns=["instrument_name"] )

lineage_df = pandas.DataFrame( [infile]*data_df.shape[0], columns=["lineage"] )

# Put the dataframe back together:
new_df = pandas.concat( [datetime_df,station_df,instrument_df,data_width_df,meta_width_df,data_df,df,lineage_df], axis=1 )
new_df.to_csv( outfile, index=False )
