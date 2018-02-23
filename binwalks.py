import os,sys,glob,re,logging
import pandas as pd
import numpy as np

offset = 50

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('binwalks')

def binwalks(xls,nbins=100):
    writer = pd.ExcelWriter(re.sub(r'_.*','binned.xlsx',xls))
    logger.info("entering "+xls)
    for sheet in ['Condition_'+str(i) for i in range(1,4) ]:
        logger.info("enterng "+sheet)
        new = generate_bins(xls,sheet,nbins)
        new = add_sides_averages(new)
        if(new.values.any()):
            new.to_excel(writer,sheet)
            logger.info("done")
        else:
            logger.error("unknown error no output!")
    writer.save()

def generate_bins(xls,sheet,nbins):
    newtable = pd.DataFrame(index=range(nbins))
    dat = pd.read_excel(xls,sheet,skiprows=[0])
    walksraw = pd.read_excel(xls,sheet,skiprows=range(1,len(dat))).columns
    walknames = list()
    walkbases = set()
    for w in walksraw:
        m =  re.match(r'(^Walk_\d+)(\.\d+)?$',w)
        if(m):
            walknames.append(w)
            if(m.group(2) is None) :
                walkbases.add(w)
    walkbases  = sorted(list(walkbases))
    for walk in walkbases:
        binned = binify(dat,walk,nbins,walknames,sheet)
        newtable = pd.concat([newtable,binned],axis=1)
        off = dat.iloc[:offset][newtable.columns]
    return pd.concat([off,newtable],ignore_index=True)
            

def binify(df,walk,nbins,walknames,sheet):
    logger.info("entering walk {:s} in condition {:s}".format(walk,sheet))
    cols = [channel for walkname,channel in zip(walknames,df.columns) if walkname.startswith(walk)]
    chunk = df.iloc[offset:][cols].dropna().values
    nrows = chunk.shape[0]
    binsize = np.floor(nrows/nbins)
    if(binsize < 1):
        logger.error('not enough data for {:d} bins ({:d}) sheet: {:s} walk: {:s}'.format(nbins,nrows,sheet,walk))
        quit()
    np.random.seed(1234)
    extras = np.random.choice(nbins,nrows % nbins,replace=False)
    ret = pd.DataFrame(chunk,columns=cols)
    bins = pd.Series(name='bins',index=range(nrows))
    b = 0
    r = 0
    while(r < nrows):
        size = binsize + 1 if b in extras else binsize
        while(size > 0):
            bins[r] = b
            size = size - 1
            r += 1
        b += 1
    ret['bins'] = bins
    ret = ret.groupby('bins').mean()
    return ret


if __name__ == '__main__':
    for f in glob.glob(sys.argv[1]+'/[0-9]*Analyzed.xlsx'):
        binwalks(f,int(sys.argv[2]));

