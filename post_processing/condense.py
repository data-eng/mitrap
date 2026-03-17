import sys
import pandas

print( sys.argv[1] )

df = pandas.read_csv( sys.argv[1], names=["date","measurement","station","instrument","count"] )
df["count"] = df["count"].astype(int)

condensed_df = pandas.DataFrame( [], columns=["date"] )
condensed_df["date"] = df.date.unique()
condensed_df = condensed_df.set_index( "date" )

for i in df.index:
    d = df.loc[i,"date"]
    stn = df.loc[i,"station"].replace(" ","") 
    column = str(df.loc[i,"measurement"]) + "_" + stn
    condensed_df.loc[d,column] = int(df.loc[i,"count"])

condensed_df.to_csv( sys.argv[2] )

