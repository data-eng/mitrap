import sys
import pandas
import datetime

infile = sys.argv[1]
outfile = sys.argv[2]
date_col = sys.argv[3]
time_col = sys.argv[4]
datetime_fmt = sys.argv[5]
instrument_tz = sys.argv[6]

df = pandas.read_csv( infile )

times = []
values = []
bad_idx = []


def make_decimal( year, offset, tz ):
    epoch = datetime.datetime( year, 1, 1 ).replace( tzinfo=datetime.timezone.utc )
    return epoch + datetime.timedelta( days=offset )

def make_utc( datetime_str, datetime_fmt ):
    try: dt = pandas.to_datetime( datetime_str, format=datetime_fmt, utc=True )
    except: dt = None
    return dt

def make_tz( datetime_str, datetime_fmt, tz ):
    try: dt = pandas.to_datetime( datetime_str, format=datetime_fmt, utc=False ).tz_localize( tz = instrument_tz, ambiguous='NaT' )
    except: dt = None
    if dt == 'NaT': dt = None
    return dt

if datetime_fmt == "decimal":
    all_dt = [make_decimal(df.loc[i,date_col], df.loc[i,time_col], instrument_tz) for i in df.index]
else:
    sys.exit(1)

df = df.drop( ["Start Date","End Date","Start Year","End Year"], axis=1 )
newdf = pandas.concat( [pandas.DataFrame(all_dt,columns=["datetime"]),df], axis=1 )

newdf.to_csv( outfile, index=False )

