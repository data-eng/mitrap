import sys
import pandas
import numpy

infile = sys.argv[1]
installation = sys.argv[2]
instrument = sys.argv[3]

df = pandas.read_csv( infile, parse_dates=["datetime"] )

installation = installation.replace(" ","\\ ")
instrument = instrument.replace(" ","\\ ")
for idx in df.index:
    print( f"uf,installation={installation},instrument={instrument} concentration_cc={df.loc[idx,'concentration_cc']},valve_state={df.loc[idx,'valve_state']} {df.loc[idx,'datetime'].value}" )

