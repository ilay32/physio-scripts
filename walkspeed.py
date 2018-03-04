import tkFileDialog,serial,time,re,os,logging,threading
import serial.tools.list_ports as list_ports
import pandas as pd
import Tkinter as tk
from Tkinter import Tk,Label,Button,Entry,Scale,StringVar
from guihelpers import FileActionGUI
from tkMessageBox import showerror

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('walkspeed')


class ArduinoSonarRecorder(object):
    def __init__(self):
        self.read_lines = list()
        self.durations = list()
        self.recording = False
        self.cond = threading.Thread(None,self._start)
        #self.cond.setDaemon(True)

    def start(self):
        self.cond.start()
        self.read_lines = list()
        self.durations  = list()


    def _start(self):
        #find the arduino usb port
        # and define the Serial object if found
        port = ""
        ardi = None
        for p in list(list_ports.comports()):
            if "Arduino" in  str(p):
                port = re.sub(r'\s.*$','',str(p))
                break
        if port != "":
            ardi = serial.Serial(port,115200,timeout=0.1)
            time.sleep(0.5)
            logger.info("connected")
        else:
            raise(Exception,"couldn't find port")

        self.recording = True
        expired = 0
        start = time.time()
        now = start
        while self.recording:
            line = ardi.readline()
            if line:
                logger.info(line)
                self.read_lines.append(line)
                if ardi.read() == 'y':
                    self.durations.append(int(ardi.readline()))
                    
            #else:
                #print "read timeout expired {:d}".format(int(abs(time.time() - now - 100) < 20))
                #expired += 1
        #print expired 
        ardi.write(b's')
        conc = ardi.readline()
        logger.info(conc)
        ardi.close()
    
    def stop(self):
        self.recording = False
        self.cond.join()
        logger.info(self.read_lines)
        logger.info(self.durations)
    
      
class GUI(FileActionGUI):
    def __init__(self,master):
        super(GUI,self).__init__(master)
        row1,row2,row3 = self.set_rows(3)
        desc=Label(row1,text="Measure Average Speed of Walks")
        desc.pack(fill=tk.X,ipadx=10,ipady=10,side=tk.TOP)
        dirbutton = Button(row1,text="Save Results To",command=self.define_dir)
        dirbutton.pack(side=tk.LEFT,expand=True)

        a = Label(row1,text="as")
        a.pack(side=tk.LEFT,padx=20,expand=True)
        
        filename = Entry(row1)
        filename.insert(0,"test")
        filename.pack(side=tk.LEFT)
        self.filename = filename
        
        d = Label(row1,text="walking distance:")
        d.pack(side=tk.LEFT,padx=20)

        distance = Scale(row1,from_=2, to=15,orient=tk.HORIZONTAL)
        distance.set(10)
        distance.pack(side=tk.LEFT)
        self.distance = distance
        
        n = Label(row1,text="number of walks:")
        n.pack(side=tk.LEFT,padx=20)

        numwalks = Entry(row1)
        numwalks.insert(0,"12")
        numwalks.pack(side=tk.LEFT)
        self.numwalks = numwalks
        
        
        
        self.show_chosen = Label(row2,textvariable=self.chosen,background='white')
        self.show_chosen.pack(fill=tk.X,side=tk.LEFT,pady=10,ipady=5,ipadx=5,expand=True)

        row3.pack(fill=tk.NONE)
        self.go_button = Button(row3,text="START",command=self.default_action)
        self.go_button.pack(side=tk.LEFT,padx=10)

        self.stop_button = Button(row3,text="STOP",command=self.stop_record)
        self.stop_button.pack(side=tk.LEFT,padx=10)
        
        self.save_button = Button(row3,text="SAVE",command=self.save)
        self.save_button.pack(side=tk.LEFT,padx=10)

        self.close_button = Button(row3,text="CLOSE",command=master.destroy)
        self.close_button.pack(side=tk.LEFT,padx=10)

        
        self.recorder = None 
    
    
    def stop_record(self):
        self.recorder.stop()
        w = int(self.numwalks.get())
        durations = self.recorder.durations
        if w is None or w > 20 or w < 1:
            logger.warning("Incorrect Number of Walks", "please set the number of walks to a number between 1 and 20")
        if w != len(durations):
            logger.warning("recording set for {:d} walks, but {:d} were measured".format(w,len(durations)))


    def dir_action(self):
        self.recorder = ArduinoSonarRecorder()
        self.recorder.start()
    

    def save(self):
        f =  self.filename.get()
        f= re.sub(r'\.[a-z]{1,4}$','',f)
        f = re.sub(r'[^\w\-\.\_]','',f)
        if f == "": 
            showerror("Invalid File Name","incorrect file name: {:s}".format(self.filename.get()))

            return
        target = os.path.join(self.target,f+'.csv')
        self.chosen.set("saving data to: {:s}".format(target))
        durations = self.recorder.durations
        table = pd.DataFrame(index=range(len(durations)),columns=['walk no.','speed','duration'])
        for i,d in enumerate(durations):
            speed =  float(self.distance.get())/(float(d)/1000)
            table.iloc[i] = i+1,speed,d
        table.to_csv(target,index=False)
        logger.info("file saved")
      

if __name__ == '__main__':
    root = Tk()
    gui = GUI(root)
    root.mainloop()
