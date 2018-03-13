import BaseHTTPServer,SimpleHTTPServer,webbrowser,threading,time,json,os,re

HOST_NAME = 'localhost'
PORT_NUMBER = 8000

class ExpRunner(SimpleHTTPServer.SimpleHTTPRequestHandler):
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
    
    def do_GET(self):
        m = re.match(r'(.*download\/\?file\=)(.+\.[a-z]{2,4})$',self.path)
        if m and len(m.groups()) == 2:
            print "matched"
            self.path = os.path.join(ExpRunner.savedir,m.group(2))
        return SimpleHTTPServer.SimpleHTTPRequestHandler.do_GET(self)


    def do_POST(self):
        self._set_headers()
        command = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        if command['command'] == 'stop':
            print "shutting down server"
            server_stop.start()
            self.wfile.write("the server has shutdown")
        if command['command'] == 'save':
            print "saving"
            try:
                self.save_data(command['data'])
                self.wfile.write("saved")
                print "saved to "+command['data']['saveto']
            except Exception as e:
                self.wfile.write(str(e))
        #return SimpleHTTPServer.SimpleHTTPRequestHandler.do_POST(self)

    def save_data(self,dat):
        if not os.path.isdir(ExpRunner.savedir):
            os.mkdir(ExpRunner.savedir)
        g = dat['globals']
        start = g['start_time']
        with open(os.path.join(ExpRunner.savedir,dat['saveto']),'w') as f:
            # write the walks table
            f.write("walk no., absolute start, absolute end, relative start, relative end, duration, speed m/s, distractor digits, remembered as \n")
            for i,w in enumerate(dat['walkdata']):
                isdist = str(i) in dat['distractions'].keys()
                f.write("{:d},{:d},{:d},{:d},{:d},{:d},{:.5f}".format(i,w[0],w[1],w[0] - start,w[1] - start,w[1] - w[0],float(1000*g['dWalks'])/(w[1] - w[0])))
                if isdist:
                    d = dat['distractions'][str(i)]
                    f.write(",{:s},{:s}".format(d[0],d[1]))
                else:
                    f.write(",,")
                f.write("\n")
            f.write("\n")
            # write the globals
            for k,v in g.items():
                if k != 'start_time':
                    f.write("{:s}:,{:s}\n".format(k,str(v)))
            f.write("start:,{:s},unix stamp:,{:f}".format(time.ctime(start/1000),start/1000))
        return True

httpd = BaseHTTPServer.HTTPServer((HOST_NAME, PORT_NUMBER), ExpRunner)
    
def runserver():
    print time.asctime(), "Server Starts - %s:%s" % (HOST_NAME, PORT_NUMBER)
    httpd.serve_forever()
    

def killserver():
    httpd.shutdown()
    httpd.socket.close()


if __name__ == '__main__':
    server_go = threading.Thread(None,runserver)
    server_stop = threading.Thread(None,killserver)
    server_stop.setDaemon(True)
    server_go.start()
    webbrowser.open('http://localhost:8000/wcapp/')

