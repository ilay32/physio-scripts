import os,sys,glob,re,logging
import pandas as pd
import numpy as np

import tkinter as tk
from tkinter import Tk, Label, Button, StringVar, Scrollbar,Scale, Frame,Text
from tkinter.filedialog import askopenfilename,askdirectory
from tkinter.messagebox import showerror



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
        expand=tk.N+tk.S+tk.E+tk.W
        self.master = master
        self.target = None
        frame = Frame(master,padx=20,width=350,height=400)
        master.rowconfigure(5, weight=1)
        master.columnconfigure(5, weight=1)
        master.title("Physio Lab Scripts") 
        master.geometry("500x300")
        frame.grid(sticky=expand)
 
        
        desc=Label(frame,text="Unify Walk Lengths by mean-Binning the Time Series")
        desc.grid(row=0,column=0,columnspan=5,sticky=expand,pady=20)


        dirbutton = Button(frame,text="Select Folder",command=self.define_dir)
        dirbutton.grid(row=1, column=0,sticky=tk.W)
        
        o = Label(frame,text="or")
        o.grid(row=1,column=1,columnspan=3,sticky=expand)
        
        filebutton = Button(frame,text="Select Specific File", command=self.define_file)
        filebutton.grid(row=1, column=5,sticky=tk.E)
        
        nb = Label(frame,text="Number of Bins:",pady=10)
        nb.grid(row=2,column=0,sticky=tk.W)

        scale = Scale(frame,from_=0, to=150,orient=tk.HORIZONTAL)
        scale.set(100)
        scale.grid(row=2,column=1,columnspan=4,sticky=expand)
        self.scale = scale
        
        self.chosen = StringVar()
        self.chosen_base = "action target:"
        self.chosen.set(self.chosen_base)
        self.show_chosen = Label(frame,textvariable=self.chosen)
        self.show_chosen.grid(row=3,column=0,columnspan=5,pady=20,sticky=tk.W)

        self.go_button = Button(frame,text="GO")
        self.go_button.grid(row=4,column=1,sticky=tk.W)
        
        self.close_button = Button(frame,text="Close", command=master.quit)
        self.close_button.grid(row=4,column=3,sticky=tk.E)
        
        
                
    def define_dir(self):
        dirname = askdirectory(mustexist=True)
        if dirname:
            try:
                assert os.path.isdir(dirname), "something's wrong. can't locate {:s}".format(dirname)
                self.go_button.configure(command=self.dir_action)
                self.target = dirname
                self.chosen.set(self.chosen_base+" "+self.target)
                
            except:
                showerror("Open Source File", "Failed to read file\n'{:s}'".format(dirname))
    
    def define_file(self):
        specific = askopenfilename(filetypes=[("Template files", "*.xls*")])
        if specific:
            try:
                assert os.path.isfile(specific), "something's wrong. can't locate {:s}".format(specific)
                self.go_button.configure(command=self.file_action)
                self.target = specific
                self.chosen.set(self.chosen_base+" "+self.target)

            except Exception as e:
                showerror("Open Source File","Failed to read file\n'{:s}'\n{:s}".format(specific,str(e)))
        
    def file_action(self): 
        global root
        root.quit()
        with BiniFier(self.target,self.scale.get()) as binner:
            binner.process()

    def dir_action(self):
        targets =  glob.glob(os.path.join(self.target,'[0-9]*Analyzed.xlsx'))
        if(len(targets) == 0) :
            showerror("No Appropriate files","can't find any *Analyzed.xlsx in\n'{:s}'".format(self.target))
            return
        global root
        root.quit()
        for f in targets:
            with BiniFier(f,self.scale.get()) as binner:
                binner.process()

if __name__ == '__main__':
    root = Tk()
    gui = GUI(root)
    root.mainloop()
