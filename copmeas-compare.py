import os,sys
import numpy as np
import pandas as pd
from scipy.stats import ttest_rel

key = [
    "mean COP X",
    "mean COP y", 
    "SD X",
    "SD Y",
    "mean range X",
    "mean range Y",
    "mean median pf X",
    "mean median pf Y", 
    "mean velocity X", 
    "mean velocity Y",
    "mean velociy R",
    "sway area" 
]

def consolidate(d):
    files = os.listdir(d)
    df = pd.DataFrame(columns=key,index=range(len(files)))
    for i,f in enumerate(files):
        for j,l in enumerate(open(os.path.join(d,f)).readlines()):
            df.iloc[i][key[j]] = float(l.strip())
    return df

if __name__ == '__main__':
    tread_data = consolidate(sys.argv[1])
    plate_data = consolidate(sys.argv[2])
    #writer = pd.ExcelWriter('cop-compare.xlsx')
    #tread_data.to_excel(writer,'treadmill',index=False)
    #plate_data.to_excel(writer,'forceplate',index=False)

    for c in tread_data.columns:
        print c
        print ""
        print ttest_rel(tread_data[c],plate_data[c]) 
