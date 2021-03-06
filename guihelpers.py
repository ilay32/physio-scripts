import os
import tkinter as tk
from tkinter import Tk, Label, Button, StringVar, Scrollbar,Scale, Frame,Text,Entry
from tkinter.filedialog import askopenfilename,askdirectory
from tkinter.messagebox import showerror

class FileActionGUI(object):
    def __init__(self,master):
        master.title("Physio Lab Scripts") 
        mainframe = Frame(master,padx=10)
        self.master = master
        mainframe.pack(expand=True)
        mainframe.pack_propagate(True)
        self.mainframe = mainframe
        self.target = None
        self.chosen = StringVar()
        self.chosen_base = "action target:"
        self.chosen.set("!!! data destination not set!!!")
        

        self.home = os.environ.get('HOME') or os.environ.get('HOMEPATH') or os.getcwd()
    
    def default_action(self):
        showerror("Target not Set","Please set either a file or a folder")
    
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
        announcer = "Data File"
        types = ["xls*","csv","tsv","txt"]
        ftypes = [(announcer,"*"+t) for t in types]
        specific = askopenfilename(filetypes=ftypes,initialdir=self.home)
        if specific:
            try:
                assert os.path.isfile(specific), "something's wrong. can't locate {:s}".format(specific)
                self.go_button.configure(command=self.file_action)
                self.target = specific
                self.chosen.set(self.chosen_base+" "+self.target)

            except Exception as e:
                showerror("Open Source File","Failed to read file\n'{:s}'\n{:s}".format(specific,str(e)))
 
    def set_rows(self,n):
        ret = list()
        for i in range(1,n+1):
            row = Frame(self.mainframe)
            row.pack(fill=tk.X,pady=5,side=tk.TOP)
            ret.append(row)
        return ret

    def file_action(self):
        raise(NotImplementedError,"it seems the child class {:s} has not implemented the file_action method".format(self.__class__.__name__))

    def dir_action(self):
        raise(NotImplementedError,"it seems the child class {:s} has not implemented the dir_action method".format(self.__class__.__name__))

