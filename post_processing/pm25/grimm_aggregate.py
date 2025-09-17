import pandas as pd
import numpy as np
from multiprocessing import Pool, cpu_count

def CDepict(c):
    v = ['P', 'C0:', 'C0;', 'c0:', 'c0;', 'C1:', 'C1;', 'c1:', 'c1;', 'C2:', 'C2;', 'c2:', 'c2;', 
         'C3:', 'C3;', 'c3:', 'c3;', 'C4:', 'C4;', 'c4:', 'c4;', 'C5:', 'C5;', 'c5:', 'c5;', 
         'C6:', 'C6;', 'c6:', 'c6;', 'C7:', 'C7;', 'c7:', 'c7;', 'C8:', 'C8;', 'c8:', 'c8;', 
         'C9:', 'C9;', 'c9:', 'c9;']
    return v.index(c)


table1 = pd.read_csv( "temp-input.grimm",
                      header=None, na_filter=False, names=range(17), low_memory=False )
vec = [ np.nan, 'P',
        'C0:','C0;','c0:','c0;', 'C1:','C1;','c1:','c1;',
        'C2:','C2;','c2:','c2;', 'C3:','C3;','c3:','c3;',
        'C4:','C4;','c4:','c4;', 'C5:','C5;','c5:','c5;',
        'C6:','C6;','c6:','c6;', 'C7:','C7;','c7:','c7;',
        'C8:','C8;','c8:','c8;','C9:','C9;','c9:','c9;' ]

if not table1.iloc[:, 0].isin(vec).all():
    tbl = table1[table1.iloc[:, 0].isin(vec)]
    nslines = len(table1) - len(tbl)
else:
    tbl = table1
    nslines = 0

bad_idx = []
prev_idx = None
for i in range(len(tbl.index)-1):
    idx0 = tbl.index[i]
    idx1 = tbl.index[i+1]
    dd = CDepict(tbl.loc[idx0,0]) - CDepict(tbl.loc[idx1,0])
    if (dd != -1) and (dd != 40):
        print( f"Bad {idx0} ; {tbl.loc[idx0,0]} {CDepict(tbl.loc[idx0,0])} ; {tbl.loc[idx1,0]} {CDepict(tbl.loc[idx1,0])}" )
        bad_idx.append(idx0)
        j = i
        while (j>=0) and (tbl.loc[tbl.index[j],0] != 'c9;'):
            bad_idx.append(tbl.index[j])
            j -= 1
        j = i
        while (j < len(tbl)) and (tbl.loc[tbl.index[j],0] != 'P'):
            bad_idx.append(tbl.index[j])
            j += 1

#if t2[-1] != "c9;":
#    a = len(t2) - 1
#    while t2[a] != "c9;":
#        bad_idx.append(a)
#        a -= 1

bad_idx = list(set(bad_idx))

nfmins = len(bad_idx)
print( f"Number of lines of uncompleted minutes removed: {nfmins}" )

rmv = tbl.drop(bad_idx) if bad_idx else tbl
rows = len(rmv)
rmv.index = range(1, rows + 1)

# Initialize dataframe with -1.
# Negative values never appear, and we must remove
# unwritten the cells with post-editing of the CSV
mtemp = pd.DataFrame(-1, index=range(int(rows * 5 / 41)), columns=range(17) )

# The first column is the times/channels characters
mtemp[0] = ['P', 'C_:', 'C_;', 'c_:', 'c_;'] * (rows // 41)

for i in range(rows // 41):
    mtemp.iloc[i * 5, 0] = str( rmv.iloc[i * 41, 0] )
    # Copy the times lines (P lines)
    for j in range(1,17):
        mtemp.iloc[i * 5, j] = int( rmv.iloc[i * 41, j] )
    # Aggregate the channels (C lines)
    for j in range(1, 10):
        for k in range(1, 5):
            ll = [rmv.iloc[i * 41 + k, j], rmv.iloc[i * 41 + k + 4, j],
                  rmv.iloc[i * 41 + k + 2 * 4, j], rmv.iloc[i * 41 + k + 3 * 4, j],
                  rmv.iloc[i * 41 + k + 4 * 4, j], rmv.iloc[i * 41 + k + 5 * 4, j],
                  rmv.iloc[i * 41 + k + 6 * 4, j], rmv.iloc[i * 41 + k + 7 * 4, j],
                  rmv.iloc[i * 41 + k + 8 * 4, j], rmv.iloc[i * 41 + k + 9 * 4, j]]
            vv = 0
            for l in ll:
                try:
                    vv += int(l)
                    mtemp.iloc[i * 5 + k, j] = vv
                except:
                    if l != "": print( f"Funny value: {l}" )
        # end for k in range(1, 5)
    # end for j in range(1, 10)


for i in range(len(mtemp) // 5):
    mtemp.iloc[5 * i - 1, 9] = 0

mtemp.iloc[:, 9] = mtemp.iloc[:, 9].replace(1600, 160)
#mtemp.iloc[:, 9] = mtemp.iloc[:, 9].replace(np.nan, np.nan)

mtemp.to_csv( "temp-aggregated.csv", sep=",", header=False, index=False, na_rep="" )
