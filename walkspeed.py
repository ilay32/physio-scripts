import serial,time,re,os,logging,threading
import serial.tools.list_ports as list_ports
import pandas as pd
from guihelpers import *

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('walkspeed')


class ArduinoSonarRecorder(object):
    def __init__(self):
        self.durations = list()
        self.marks = list()
        self.recording = False
        self.last_reset = None
        self.cond = None
        self.ardi = None
        self.connect()
    
    def start(self):
        cond = threading.Thread(None,self.get_walks)
        cond.start()
        self.cond = cond
    
    def connect(self):
        for p in list(list_ports.comports()):
            if "Arduino" in  str(p):
                port = re.sub(r'\s.*$','',str(p))
                break
        if port != "":
            ardi = serial.Serial(port,115200,timeout=0.05)
            while not ardi.writable():
                continue;
            logger.info("connected")
        else:
            raise(Exception,"couldn't find port")
        self.ardi = ardi
    
    def disconnect(self):
        self.ardi.close()

    def get_walks(self):
        self.durations = list()
        self.marks = list()
        self.recording = True
        reset_acknowledged = False
        self.last_reset = time.time()
        # issue the reset command
        self.ardi.write(b'r')
        while self.recording:
            line = self.ardi.readline().decode('ascii')
            if line:
                if "tracker reset" in line:
                    read_time = time.time() 
                    lag = (read_time - self.last_reset)/2
                    if lag > 50:
                        logger.warning("unusual lag: {:f}".format(lag))
                    reset_acknowledged = True
                if not reset_acknowledged:
                    logger.warning("dumping "+line)
                else:
                    logger.info(line)
                    # actual data will follow a log line
                    # c means walk commenced, e means walk ended
                    # the third option is n, no futher data at this point
                    c = self.ardi.read()
                    if c == b'c':
                        self.marks.append(int(self.ardi.readline()))
                    elif c == b'e':
                        self.durations.append(int(self.ardi.readline())) 
        self.ardi.write(b's')
        conclusion = self.ardi.readline()
        logger.info(conclusion.decode('ascii'))

    def stop(self):
        self.recording = False
        self.cond.join()
        logger.info("durations: "+" ".join([str(d) for d in self.durations]))
        logger.info("times: "+" ".join([str(m) for m in self.marks]))
    
      
class GUI(FileActionGUI):
    def __init__(self,master):
        super(GUI,self).__init__(master)
        self.master = master
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

        self.close_button = Button(row3,text="CLOSE",command=self.terminate)
        self.close_button.pack(side=tk.LEFT,padx=10)

        
        self.recorder = ArduinoSonarRecorder()
    
    def terminate(self):
        self.recorder.disconnect()
        self.master.destroy()
    
    def stop_record(self):
        self.recorder.stop()
        w = int(self.numwalks.get())
        durations = self.recorder.durations
        if w is None or w > 20 or w < 1:
            logger.warning("Incorrect Number of Walks", "please set the number of walks to a number between 1 and 20")
        if w != len(durations):
            logger.warning("recording set for {:d} walks, but {:d} were measured".format(w,len(durations)))
        if len(durations) > 0:
            self.save()
        else:
            logger.warning("no data to save")
    
    def dir_action(self):
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
        start = self.recorder.last_reset
        marks = self.recorder.marks
        table = pd.DataFrame(index=range(len(durations)),columns=['walk no.','speed','duration','start','end'])
        for i,(d,m) in enumerate(list(zip(durations,marks))):
            speed =  float(self.distance.get())/(float(d)/1000)
            table.iloc[i] = i+1,speed,d,m,m+d
        table.to_csv(target,index=False)
        with open(target,'a') as f:
            f.write("\n")
            f.write("start:,{:s},unix stamp:,{:f}\n".format(time.ctime(start),start))
        logger.info("file saved")
      

if __name__ == '__main__':
    root = Tk()
    gui = GUI(root)
    root.mainloop()
