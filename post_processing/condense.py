import sys
import pandas

print( sys.argv[1] )

df = pandas.read_csv( sys.argv[1], names=["Date","Installation","Instrument","Num_Measurements"] )
df["Num_Measurements"] = df["Num_Measurements"].astype(int)

condensed_df = pandas.DataFrame( [], columns=["Date"] )
condensed_df["Date"] = df.Date.unique()
condensed_df = condensed_df.set_index( "Date" )

for i in df.index:
    d = df.loc[i,"Date"] 
    column = str(df.loc[i,"Installation"]) + "_" + str(df.loc[i,"Instrument"])
    condensed_df.loc[d,column] = df.loc[i,"Num_Measurements"]

condensed_df.to_csv( sys.argv[2] )

