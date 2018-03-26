# android qpython3 uses python3.2, which can't stand u'' for unicode
# this hack hooks into the import and tries to replace u'whatever' with 'whatever'
#from Imp32 import *
#try:
#    x = type(u'')
#except Exception as e:
#    installImportOverride()
#
import webbrowser,threading,time,json,os,re,glob
import http.server as hs
from openpyxl import Workbook,load_workbook

HOST_NAME = 'localhost'
PORT_NUMBER = 8000

class ExpRunner(hs.SimpleHTTPRequestHandler):
    #savedir = os.path.join(os.path.abspath(os.pardir),"corridor-walks")
    savedir = "corridor-walks"
    def do_HEAD(self):
        self._set_headers()

    def _set_headers(self):
        self.send_response(200)
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def respond(self,string):
        self.wfile.write(bytes(string,"utf-8"))
    
    def do_GET(self):
        m = re.match(r'(.*download\/\?file\=)(.+\.[a-z]{2,4})$',self.path)
        if m and len(m.groups()) == 2:
            self.path = os.path.join(ExpRunner.savedir,m.group(2))
        return hs.SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self):
        self._set_headers()
        command = json.loads(self.rfile.read(int(self.headers['Content-Length'])).decode("utf-8"))
        if command['command']  == 'check_existing':
            dest = os.path.join(ExpRunner.savedir,command['filename'])
            wb = load_workbook(dest)
            if command['sheet'] in wb.sheetnames:
                self.respond("exists")
            else:
                self.respond("absent")

        if command['command'] == 'checkfile':
            f,e = os.path.splitext(command['filename'])
            if os.path.isfile(os.path.join(ExpRunner.savedir,f+e)):
                f = self.findlast(f)
            self.respond(f+e)
        if command['command'] == 'stop':
            
            print("shutting down server")
            server_stop.start()
            self.respond("the server has shutdown")
        if command['command'] == 'save':
            try:
                self.save_data(command['data'])
                self.respond("saved")
                print("saved to "+command['data']['globals']['savefile'])
            except Exception as e:
                self.respond(str(e))
                print(str(e))
        #return SimpleHTTPServer.SimpleHTTPRequestHandler.do_POST(self)
    
    def findlast(self,file_base):
        f = file_base
        fs = glob.glob(os.path.join(ExpRunner.savedir,f+"([0-9])*"))
        if len(fs) == 0:
            return f+"(1)"
        latest = 1
        for dup in fs:
            m = re.match(r'^(.*)(\(\d+\))(\.\w{2,4})$',dup)
            if len(m.groups()) == 3:
                i = int(m.group(2).strip("()"))
                if i > latest:
                    latest = i
        return  f+"("+str(latest+1)+")"

    def save_data(self,dat):
        if not os.path.isdir(ExpRunner.savedir):
            os.mkdir(ExpRunner.savedir)
        dest = os.path.join(ExpRunner.savedir,dat['globals']['savefile'])
        subj = dat['globals']['subject']
        walks = dat['globals']['walks']
        start = walks['start_time']
        sheet = walks['shoe_type']
        if dat['globals']['newSubject']:
            wb = Workbook()
            datsheet = wb.active
            datsheet.title = walks['shoe_type']
        else:
            wb = load_workbook(dest)
            datsheet = wb.create_sheet(title=sheet)
        
        # write subject details in separate sheet
        # if not already written
        if 'subject' not in wb.sheetnames:
            subsheet = wb.create_sheet(title="subject")
            for i,(k,v) in enumerate(subj.items(),1):
                if subj['regular_sport'] == "none" and k == 'weekly_minutes':
                    continue;
                subsheet.cell(row=i,column=1,value=k.replace("_"," "))
                subsheet.cell(row=i,column=2,value=v)

        cols = [
            "walk no.", 
            "absolute start", 
            "absolute end", 
            "relative start", 
            "relative end", 
            "duration", 
            "speed m/s", 
            "distractor digits",
            "remembered as"
        ]
        # header row
        for i,c in enumerate(cols,1):
            datsheet.cell(column=i,row=1,value=c)
        # data
        for i,w in enumerate(dat['walkdata']):
            isdist = str(i) in dat['distractions'].keys()
            row = [i,w[0],w[1],w[0] - start, w[1] - start, w[1] - w[0],float(1000*walks['number'])/(w[1] - w[0])]
            if isdist: 
                row += dat['distractions'][str(i)]
            else:
                row += ["",""]
            datsheet.append(row)

        # write the parameters in the same sheet
        for i,(k,v) in enumerate(walks.items(),len(dat['walkdata'])+3):  
            if k == 'start_time' :
                datsheet.cell(row=i,column=1,value="start:")
                datsheet.cell(row=i,column=2,value=time.ctime(float(start)/1000))
                datsheet.cell(row=i,column=3,value="unix stamp:")
                datsheet.cell(row=i,column=4,value=float(start)/1000)
            else:
                datsheet.cell(row=i,column=1,value=k.replace("_"," "))
                datsheet.cell(row=i,column=2,value=v)
        # and finally    
        wb.save(filename = dest)


httpd = hs.HTTPServer((HOST_NAME, PORT_NUMBER), ExpRunner)
    
def runserver():
    print(time.asctime(), "Server Starts - %s:%s" % (HOST_NAME, PORT_NUMBER))
    httpd.serve_forever()
    

def killserver():
    httpd.shutdown()
    httpd.socket.close()


if __name__ == '__main__':
    os.chdir(os.path.dirname(__file__))
    server_go = threading.Thread(None,runserver)
    server_stop = threading.Thread(None,killserver)
    server_stop.setDaemon(True)
    server_go.start()
    webbrowser.open('http://localhost:8000/wcapp/')

