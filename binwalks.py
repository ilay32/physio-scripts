import os,sys,glob,re,logging
import pandas as pd
import numpy as np

import Tkinter as tk
from Tkinter import Tk, Label, Button, StringVar, Scrollbar,Scale, Frame,Text
from tkFileDialog import askopenfilename,askdirectory
from tkMessageBox import showerror



logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('binwalks')

class BiniFier:
    def __init__(self,srcfile,nbins=100,offset=50,sideav_numwalks=5):
        self.srcfile = srcfile
        self.dstfile = re.sub(r'_.*','_binned.xlsx',self.srcfile)
        self.nbins = nbins
        self.offset = offset
        self.walk_stats = dict()
        self.sideav_numwalks = sideav_numwalks
    
    def __enter__(self):
        logger.info("entering "+self.srcfile)
        return self

    def __exit__(self,exception_type, exception_value, traceback):
        if exception_value is not None:
            logger.error(exception_value)
        else:
            logger.info("done")

    def process(self):
        writer = pd.ExcelWriter(self.dstfile)
        for sheet in ['Condition_'+str(i) for i in range(1,4)]:
            logger.info("\tentering "+sheet)
            new = self.process_sheet(sheet)
            if(new.values.any()):
                new = self.add_sides_averages(new)
                new.to_excel(writer,sheet,index=False)
            else:
                logger.warning("failed to binify {:s} in {:s}",sheet,self.srcfile)
        wstats = self.tabulate_walkstats()
        if(wstats.values.any()):
           wstats.to_excel(writer,'walk-statistics',index=False) 
        else:
            logger.warning("failed to compile walk statistics for {:s} in {:s}",sheet,self.srcfile)
        writer.save()
    
    def add_sides_averages(self,df):
        logger.info("\t\tcollecting the side averages over {:d} walks".format(self.sideav_numwalks))
        leftcols = sorted([c for c in df.columns if re.match(r'^S[123]_',c)])[:self.sideav_numwalks*3]
        rightcols = sorted([c for c in df.columns if re.match(r'^S[456]_',c)])[:self.sideav_numwalks*3]
        df['left'] = df[leftcols].mean(axis=1)
        df['right'] = df[rightcols].mean(axis=1)
        return df

    def process_sheet(self,sheet):
        newtable = pd.DataFrame(index=range(self.nbins))
        dat = pd.read_excel(self.srcfile,sheet,skiprows=[0])
        walksraw = pd.read_excel(self.srcfile,sheet,skiprows=range(1,len(dat))).columns
        walknames = list()
        walkbases = set()
        for w in walksraw:
            m =  re.match(r'(^Walk_\d+)(\.\d+)?$',w)
            if(m):
                walknames.append(w)
                if(m.group(2) is None) :
                    walkbases.add(w)
        walkbases  = sorted(list(walkbases))
        self.walk_stats[sheet] = dict()
        for walk in walkbases:
            logger.info("\t\tentering {:s}".format(walk))
            cols = [channel for walkname,channel in zip(walknames,dat.columns) if walkname.startswith(walk)]
            chunk = dat.iloc[self.offset:][cols].dropna().values
            self.walk_stats[sheet][walk] = chunk.shape[0]
            assert chunk.shape[0]/self.nbins >= 1, "not enough data for {:d} bins ({:d}) sheet: {:s} walk: {:s}".format(self.nbins,chunk.shapepe[0],sheet,walk)
            binned = self.binify(chunk,cols)
            newtable = pd.concat([newtable,binned],axis=1)
            off = dat.iloc[:self.offset][newtable.columns]
        return pd.concat([off,newtable],ignore_index=True)
                
    def tabulate_walkstats(self):
        logger.info("\tcollectig the walk lengths")
        d = self.walk_stats
        walks = sum([list(item.keys()) for item in d.values()],[])
        walks.sort(key=lambda w : int(re.sub(r'[^\d]','',w)))
        ret = list()
        rows = 0
        for sheet,walks in d.items():
            cond = re.sub(r'[^\d]','',sheet)
            for walkname,walklength in walks.items():
                ret.append({
                    'walk' : int(re.sub(r'[^\d]','',walkname)), 
                    'length': walklength, 
                    'condition' : int(cond)
                }) 
        return pd.DataFrame(ret).sort_values(by='walk')
            
    def binify(self,ndarr,column_names):
        nrows = ndarr.shape[0]
        binsize = np.floor(nrows/self.nbins)
        np.random.seed(1234)
        extras = np.random.choice(self.nbins,nrows % self.nbins,replace=False)
        ret = pd.DataFrame(ndarr,columns=column_names)
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

class GUI:
    def __init__(self,master):
        master.title("Physio Lab Scripts") 
        mainframe = Frame(master,padx=10)
        self.master = master
        mainframe.pack(expand=True)
        mainframe.pack_propagate(True)
        self.mainframe = mainframe
        self.target = None
        row1,row2,row3,row4 = self.set_rows(4)

        
        desc=Label(row1,text="Unify Walk Lengths by mean-Binning the Time Series")
        desc.pack(fill=tk.X,ipadx=10,ipady=10,side=tk.TOP)

        dirbutton = Button(row1,text="Select Folder",command=self.define_dir)
        dirbutton.pack(side=tk.LEFT,expand=True)
        
        o = Label(row1,text="or")
        o.pack(side=tk.LEFT,padx=20,expand=True)
        
        filebutton = Button(row1,text="Select Specific File", command=self.define_file)
        filebutton.pack(side=tk.LEFT,expand=True)
        

        self.chosen = StringVar()
        self.chosen_base = "action target:"
        self.chosen.set(self.chosen_base+" please choose")
        self.show_chosen = Label(row2,textvariable=self.chosen,background='white')
        self.show_chosen.pack(fill=tk.X,side=tk.LEFT,pady=10,ipady=5,ipadx=5,expand=True)

        nb = Label(row3,text="Number of Bins:",pady=10)
        nb.pack(side=tk.LEFT)

        scale = Scale(row3,from_=0, to=150,orient=tk.HORIZONTAL)
        scale.set(100)
        scale.pack(side=tk.LEFT,fill=tk.X,expand=True)
        self.scale = scale
        
        row4.pack(fill=tk.NONE)
        self.go_button = Button(row4,text="GO")
        self.go_button.pack(side=tk.LEFT,padx=10)
        
        self.close_button = Button(row4,text="Close",command=master.destroy)
        self.close_button.pack(side=tk.RIGHT,padx=10)

        self.home = os.environ.get('HOME') or os.environ.get('HOMEPATH') or os.getcwd()

       
    def set_rows(self,n):
        ret = list()
        for i in range(1,n+1):
            row = Frame(self.mainframe)
            row.pack(fill=tk.X,pady=5,side=tk.TOP)
            ret.append(row)
        return ret

    def define_dir(self):
        dirname = askdirectory(mustexist=True,initialdir=self.home)
        if dirname:
            try:
                assert os.path.isdir(dirname), "something's wrong. can't locate {:s}".format(dirname)
                self.go_button.configure(command=self.dir_action)
                self.target = dirname
                self.chosen.set(self.chosen_base+" "+self.target)
                
            except:
                showerror("Open Source File", "Failed to read file\n'{:s}'".format(dirname))
    
    def define_file(self):
        specific = askopenfilename(filetypes=[("Data Sheets", "*Analyzed.xls*")],initialdir=self.home)
        if specific:
            try:
                assert os.path.isfile(specific), "something's wrong. can't locate {:s}".format(specific)
                self.go_button.configure(command=self.file_action)
                self.target = specific
                self.chosen.set(self.chosen_base+" "+self.target)

            except Exception as e:
                showerror("Open Source File","Failed to read file\n'{:s}'\n{:s}".format(specific,str(e)))
        
    def file_action(self): 
        with BiniFier(self.target,self.scale.get()) as binner:
            binner.process()

    def dir_action(self):
        targets =  glob.glob(os.path.join(self.target,'[0-9]*Analyzed.xlsx'))
        if(len(targets) == 0) :
            showerror("No Appropriate files","can't find any *Analyzed.xlsx in\n'{:s}'".format(self.target))
            return
        for f in targets:
            with BiniFier(f,self.scale.get()) as binner:
                binner.process()

if __name__ == '__main__':
    root = Tk()
    gui = GUI(root)
    root.mainloop()
