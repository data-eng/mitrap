
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
created on tue may 28 15:56:28 2024

@author: stergios
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
filename = '/home/stergios/Dropbox/yah/MITRAP/MPSS_DEM_DIAM.csv'

a = pd.read_table(filename, delimiter=',', header=None)
a_diam = a.values[0,:].astype(float)
DeltalnD = np.median(np.log10(a_diam[1:]/a_diam[:-1]))
filename2 = '/home/stergios/Dropbox/yah/MITRAP/Florence_MPSS_DIAM.csv'

b = pd.read_table(filename2, delimiter=',', header=None)
b_diam = b.values[0,:].astype(float)
b_inv =  b.values[1,:].astype(float)

DeltalnDb = np.median(np.log10(b_diam[1:]/b_diam[:-1]))

#y = np.zeros((np.size(df_MPSS_raw.values[:,0]),np.size(delta.Dp)))
y = np.zeros(np.size(a_diam))

y = np.interp(a_diam, b_diam, b_inv)

y_sum = np.sum(y * DeltalnD)
b_sum = np.sum(b_inv*DeltalnDb)

plt.plot(a_diam, y, b_diam, b_inv,'r')
plt.show()

