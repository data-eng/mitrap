import sys
import pandas

cols_dCnt = ['dCnt_1', 'dCnt_2', 'dCnt_3', 'dCnt_4', 'dCnt_5', 'dCnt_6', 'dCnt_7', 'dCnt_8', 'dCnt_9', 'dCnt_10', 'dCnt_11', 'dCnt_12', 'dCnt_13', 'dCnt_14', 'dCnt_15', 'dCnt_16', 'dCnt_17', 'dCnt_18', 'dCnt_19', 'dCnt_20', 'dCnt_21', 'dCnt_22', 'dCnt_23', 'dCnt_24', 'dCnt_25', 'dCnt_26', 'dCnt_27', 'dCnt_28', 'dCnt_29', 'dCnt_30']

cols_size = ['Size_1', 'Size_2', 'Size_3', 'Size_4', 'Size_5', 'Size_6', 'Size_7', 'Size_8', 'Size_9', 'Size_10', 'Size_11', 'Size_12', 'Size_13', 'Size_14', 'Size_15', 'Size_16', 'Size_17', 'Size_18', 'Size_19', 'Size_20', 'Size_21', 'Size_22', 'Size_23', 'Size_24', 'Size_25', 'Size_26', 'Size_27', 'Size_28', 'Size_29', 'Size_30']

sizes = [300, 350, 400, 450, 500, 550, 600, 650, 700, 800, 900, 1000, 1250, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000, 6500, 7000, 7500, 8000, 8500, 9250, 10000]

df = pandas.read_csv( sys.argv[1], index_col="RecordNo" )
df["datetime"] = pandas.to_datetime( df['Date'] + ' ' + df['Time'], format='%m/%d/%y %H:%M:%S' )
df["station"] = [sys.argv[2]] * len(df)
df["instrument"] = [sys.argv[3]] * len(df)
cols = ["datetime","station","instrument"]
cols.extend( cols_dCnt )
df1 = df[cols]
#df1["pm25_native"] = df["Pm2p5"]
df1.to_csv( sys.argv[4], index=False, header=False )


# from:
# RecordNo,Date,Time,SmpSecs,AvgMlpm,ErrStatus,ChEnaMask,ChAlmMask,XsnEnaMsk,XsnAlmMsk,OutCfgMsk,OutChnMsk,Location,PmFactor,Pm2p5,Pm10,TpcCm3,None0,None1,None2,None3,None4,None5,None6,None7,CheckByte,Chn_1,Size_1,dCnt_1,sCnt_1,dM3_1,sM3_1,dFt3_1,sFt3_1,dUgM3_1,sUgM3_1,Chn_2,Size_2,dCnt_2,sCnt_2,dM3_2,sM3_2,dFt3_2,sFt3_2,dUgM3_2,sUgM3_2,Chn_3,Size_3,dCnt_3,sCnt_3,dM3_3,sM3_3,dFt3_3,sFt3_3,dUgM3_3,sUgM3_3,Chn_4,Size_4,dCnt_4,sCnt_4,dM3_4,sM3_4,dFt3_4,sFt3_4,dUgM3_4,sUgM3_4,Chn_5,Size_5,dCnt_5,sCnt_5,dM3_5,sM3_5,dFt3_5,sFt3_5,dUgM3_5,sUgM3_5,Chn_6,Size_6,dCnt_6,sCnt_6,dM3_6,sM3_6,dFt3_6,sFt3_6,dUgM3_6,sUgM3_6,Chn_7,Size_7,dCnt_7,sCnt_7,dM3_7,sM3_7,dFt3_7,sFt3_7,dUgM3_7,sUgM3_7,Chn_8,Size_8,dCnt_8,sCnt_8,dM3_8,sM3_8,dFt3_8,sFt3_8,dUgM3_8,sUgM3_8,Chn_9,Size_9,dCnt_9,sCnt_9,dM3_9,sM3_9,dFt3_9,sFt3_9,dUgM3_9,sUgM3_9,Chn_10,Size_10,dCnt_10,sCnt_10,dM3_10,sM3_10,dFt3_10,sFt3_10,dUgM3_10,sUgM3_10,Chn_11,Size_11,dCnt_11,sCnt_11,dM3_11,sM3_11,dFt3_11,sFt3_11,dUgM3_11,sUgM3_11,Chn_12,Size_12,dCnt_12,sCnt_12,dM3_12,sM3_12,dFt3_12,sFt3_12,dUgM3_12,sUgM3_12,Chn_13,Size_13,dCnt_13,sCnt_13,dM3_13,sM3_13,dFt3_13,sFt3_13,dUgM3_13,sUgM3_13,Chn_14,Size_14,dCnt_14,sCnt_14,dM3_14,sM3_14,dFt3_14,sFt3_14,dUgM3_14,sUgM3_14,Chn_15,Size_15,dCnt_15,sCnt_15,dM3_15,sM3_15,dFt3_15,sFt3_15,dUgM3_15,sUgM3_15,Chn_16,Size_16,dCnt_16,sCnt_16,dM3_16,sM3_16,dFt3_16,sFt3_16,dUgM3_16,sUgM3_16,Chn_17,Size_17,dCnt_17,sCnt_17,dM3_17,sM3_17,dFt3_17,sFt3_17,dUgM3_17,sUgM3_17,Chn_18,Size_18,dCnt_18,sCnt_18,dM3_18,sM3_18,dFt3_18,sFt3_18,dUgM3_18,sUgM3_18,Chn_19,Size_19,dCnt_19,sCnt_19,dM3_19,sM3_19,dFt3_19,sFt3_19,dUgM3_19,sUgM3_19,Chn_20,Size_20,dCnt_20,sCnt_20,dM3_20,sM3_20,dFt3_20,sFt3_20,dUgM3_20,sUgM3_20,Chn_21,Size_21,dCnt_21,sCnt_21,dM3_21,sM3_21,dFt3_21,sFt3_21,dUgM3_21,sUgM3_21,Chn_22,Size_22,dCnt_22,sCnt_22,dM3_22,sM3_22,dFt3_22,sFt3_22,dUgM3_22,sUgM3_22,Chn_23,Size_23,dCnt_23,sCnt_23,dM3_23,sM3_23,dFt3_23,sFt3_23,dUgM3_23,sUgM3_23,Chn_24,Size_24,dCnt_24,sCnt_24,dM3_24,sM3_24,dFt3_24,sFt3_24,dUgM3_24,sUgM3_24,Chn_25,Size_25,dCnt_25,sCnt_25,dM3_25,sM3_25,dFt3_25,sFt3_25,dUgM3_25,sUgM3_25,Chn_26,Size_26,dCnt_26,sCnt_26,dM3_26,sM3_26,dFt3_26,sFt3_26,dUgM3_26,sUgM3_26,Chn_27,Size_27,dCnt_27,sCnt_27,dM3_27,sM3_27,dFt3_27,sFt3_27,dUgM3_27,sUgM3_27,Chn_28,Size_28,dCnt_28,sCnt_28,dM3_28,sM3_28,dFt3_28,sFt3_28,dUgM3_28,sUgM3_28,Chn_29,Size_29,dCnt_29,sCnt_29,dM3_29,sM3_29,dFt3_29,sFt3_29,dUgM3_29,sUgM3_29,Chn_30,Size_30,dCnt_30,sCnt_30,dM3_30,sM3_30,dFt3_30,sFt3_30,dUgM3_30,sUgM3_30


#to:
#Datetime,Station,Instrument,Concentration...,
