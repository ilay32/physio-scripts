import os,sys
import numpy as np
import pandas as pd
from scipy.stats import t_test

key = [
    "Average of mean COP from each trial",
    "Average of mean COP from each trial", 
    "Standard Deviation of trial means",
    "Standard Deviation of trial means",
    "Average of COP range from each trial",
    "Average of COP range from each trial",
    "Average Median Power Frequency",
    "Average Median Power Frequency", 
    "Average of trial Mean velocities", 
    "Average of trial Mean velocities",
    "Average of trial Mean velocities",
    "Average Sway Area per second- area enclosed by COP" 
]

def consolidate(d):
    files = os.listdir(d)
    df = pd.DataFrame(columns=key)
    for i,f in enumerate(files):
        for j,l in enumerate(f.readlines()):
            df.loc[i][key[j]] = float(l)


if __name__ == '__main__':
    tread_data = consolidate(sys.argv[1])
    plate_data = consolidate(sys.argv[2])
    for c in tread_data.columns:
        print c
        print ""
        print t_test(tread_data[c],plate_data[c]) 
