//helpers
function randomK(k,range) {
    if(k < 1) {
        return;
    }
    ret = [];
    while(k) {
        r = Math.floor(Math.random()*range)
        if(ret.indexOf(r) < 0) {
            ret.push(r);
            k--;
        }
    }
    return ret
}
//  this class keeps track of the experiment and tells
//  the angular controller what is the next screen to show
function stateCycler(nw) {
    // set sum class variables
    this.num_walks = nw;
    this.walk = -1;
    this.state = 'start';
    this.distractors = [];
    
    // generate the random selection of walks that include
    // the distractor task
    this.dists = function(n) {
        // how many walks with distractor
        var quota = Math.floor(n/2),
            ret = [];
        this.distractors = randomK(quota,n);
    }
    
    // set the walks that include a distractor
    this.dists(this.num_walks);
    this.is_distractor = function() {
        return this.distractors.indexOf(this.walk) > -1;
    }
    this.next_is_distractor = function() {
        return this.distractors.indexOf(this.walk + 1) > -1;
    }
    this.next = function() {
        switch(this.state) {
            case 'start':
                this.state = 'prewalk';
            break;
            case 'prewalk':
                if(this.walk ==  this.num_walks - 1) {
                    this.state = 'end';
                }
                else{
                    this.walk++;
                    if(this.is_distractor()) {
                        this.state = 'distractor';
                    }
                    else {
                        this.state = 'walk';
                    }
                }
            break;
            case 'walk':
                this.state = 'walk';
                if(this.is_distractor()) {
                    this.state = 'report';
                }
                else {
                    this.state = 'prewalk';
                }
            break;
            case 'distractor':
                this.state = 'walk';
            break;
            case 'report':
                this.state = 'prewalk';
            break;
            case 'end':
                this.state = 'start';
            break;
            default:
                this.state = 'end';
            break;
        }
    }
    
};

angular.module('walkControl', []).controller(
    'RunExp', ['$scope','$http','$timeout','$interval','$window', function($scope,$http,$timeout,$interval,$window) {
    // data for saving
    $scope.glob = {};
    $scope.glob.nWalks = 12;
    $scope.glob.dWalks = 10;
    $scope.glob.subjectName = 'yosi';
    $scope.glob.subjectAge = 4;
    
    
    //helper vars
    $scope.incSaveto = false;
    $scope.numSaves = 0;
    $scope.saveFileExt = ".csv";
    $scope.saveFile = $scope.glob.subjectName+$scope.saveFileExt;
    $scope.srvMessage = "";
    $scope.maincontent = "start.html";
    $scope.prewalkText = "";
    $scope.stopper_is_running = false;
    $scope.walkTime = 0;
    $scope.reportKeys = [0,1,2,3,4,5,6,7,8,9];
    $scope.seqEntered = "";
    $scope.incNext = false;
    $scope.nextDisabled = false;
    $scope.distractorLength = 5;
    var state = null;
    var stopper = undefined;
    var log = {
        globals : {},
        walkdata  : [],
        distractions : {},
        saveto : ""
    };
    $scope.goFull = function() {
    	// Supports most browsers and their versions.
		element = document.body;
    	var requestMethod = element.requestFullScreen || element.webkitRequestFullScreen || element.mozRequestFullScreen || element.msRequestFullScreen;
		// Native full screen.
		if (requestMethod) { 
			requestMethod.call(element);
		} 
 	}

    $scope.ufilename = function(name) {
        $scope.saveFile  = name+$scope.saveFileExt;
    }
    
	$scope.rpress = function(k) {
        if($scope.reportKeys.indexOf(parseInt(k)) > -1) {
            $scope.seqEntered += k;
        }
        else if(k == 'fixone') {
            $scope.seqEntered = $scope.seqEntered.substring(0,$scope.seqEntered.length - 1);
        }
        else if(k == 'clear') {
            $scope.seqEntered = "";
        }
        else if(k == 'done') {
            log.distractions[state.walk].push($scope.seqEntered);
            $scope.seqEntered = "";
            $scope.next();
        }
        else {
            $scope.srvMessage = "invalid action";
        }
    }
    
    $scope.initialize = function(n) {
        $scope.glob.nWalks = angular.copy(n)
        state = new stateCycler(n);
        log.saveto = $scope.glob.subjectName+$scope.saveFileExt;
        log.globals = $scope.glob; 
        log.globals['start_time'] = Date.now();
        $scope.next();
    }
    $scope.download = function() {
        if($scope.numSaves < 1) {
            $scope.srvMessage = "nothing to save yet";
            return;
        }
        window.open('http://localhost:8000/download/?file='+log.saveto);
    }
    $scope.terminate = function() {
        $scope.stopping = "stopping";
        $http({
            url: '/',
            method: "POST",
            headers : {
                'Content-Type' : 'text/html'
            },
            data : {
                command: 'stop'
            }
        }).then(
            function succ(r) {
                $scope.srvMessage = r.data;
            },
            function fail(r) {
                $scope.srvMessage = "couldn't stop";
            }
        );
    }
    
    $scope.stopper_stop = function() {
        $scope.stopper_is_running = false;
        $scope.nextDisabled = false;
    }
    
    $scope._stopper_stop = function() {
        if(angular.isDefined(stopper)) {
            $interval.cancel(stopper);
            stopper = undefined;
        }
    }
    
    $scope.stopper_start = function() {
        var walk_start = Date.now();
        $scope.stopper_is_running = true;
        stopper = $interval(function(s) {
            if($scope.stopper_is_running) {
                $scope.walkTime = (Date.now() - s)/1000;
            }
            else {
                log.walkdata[state.walk] = [s,Date.now()];
                $scope._stopper_stop();
            }
        },100,0,true,walk_start);
    }



    $scope.save = function() {
        $http.post('/', {
            command: 'save',
            data : log
        }).then(
            function succ(r) {
                $scope.srvMessage = r.data;
                if(r.data == "saved") {
                    $scope.numSaves++;
                    $scope.incSaveto = true;
                }
            },
            function fail(r) {
                $scope.srvMessage = "couldn't save";
            }
        );
    }
    $scope.recloop = function(arr,cur,delay) {
        if(cur == arr.length) {
            $scope.nextDisabled = false;
            return;
        }
        $scope.distDigit = arr[cur];
        cur++;
        $timeout($scope.recloop,delay,true,arr,cur,delay);
    }
    
    $scope.distractor = function() {
        $scope.nextDisabled = true;
        var rdigits = randomK($scope.distractorLength,10);
        $scope.recloop(rdigits,0,1000);
        log.distractions[state.walk] = [rdigits.join("")]
    }
    
    
    $scope.next = function(){
        $timeout(function() {
            $scope.srvMessage = "";
        },1000);
        state.next();
        if(state.next_is_distractor()){
            $scope.prewalkText = "Please prepare subject for distractor task";
        }
        else{
            $scope.prewalkText = "walk "+(state.walk+1)+" is starting";
        }
        if(state.state == 'prewalk' && state.walk > 0) {
            $scope.save();
        }
        $scope.maincontent = state.state+'.html';
        if(state.state == 'distractor') {
            $scope.distractor();
        }
        if(state.state == 'walk') {

            $scope.nextDisabled = true;
            $scope.walkTime = 0.000;
        }
        $scope.incNext = ['start','report'].indexOf(state.state) == -1;
    }
}]);

