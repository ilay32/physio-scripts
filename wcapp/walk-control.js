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

// represent floats with constant
// length after the decimal points
function frep(f,decimals) {
    var parts = f.toString().split("."),
        units =  parts[0],
        fraction = "0".repeat(decimals);
    if(decimals == 0) {
        return units;
    }
    if(decimals == 1) {
        fraction = parts.length == 2 ? parts[1].charAt(0) : "0";
    }
    if(parts.length == 2) {
        var l = parts[1].length;
        if(l >= decimals) {
            fraction = parts[1].slice(0,decimals)
        }
        else {
            fraction = parts[1]+"0".repeat(decimals - l);
        }
    }
    return units+"."+fraction
}

//  this class keeps track of the experiment and tells
//  the angular controller what is the next screen to show
function stateCycler(nw) {
    // set sum class variables
    this.num_walks = nw;
    this.walk = -1;
    this.state = 'start';
    this.distractors = [];
    this.finished = false;
    
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
                this.walk++;
                this.state = 'digitsboard';
                if(this.walk ==  this.num_walks - 1) {
                    this.finished = true;
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
            case 'digitsboard':
                this.state = 'walk';
            break;
            case 'report':
                this.state = 'prewalk';
            break;
            default:
                this.state = 'prewalk';
            break;
        }
    }
};
// this a simple version of the state cycler for
// controling the single task part of the experiment
function singletaskCycler(nt) {
    this.numtrials = nt;
    this.trial = -1;
    this.finished = false;
    this.state = 'start';
    
    this.is_distractor = function() {
        return true;
    }

    this.next = function() {
        switch(this.state) {
            default:
            case 'start':
                this.state = 'prewalk';
            break;
            case 'prewalk' :
                this.state = 'digitsboard';
                this.trial++;
                if(this.trial == this.numtrials - 1) {
                    this.finished = true;
                }
            break;
            case 'digitsboard' :
                this.state = 'trial';
            break;
            case 'trial':
                this.state = 'report';
            break;
            case 'report' :
                this.state = 'prewalk'
            break;
        }
    }
}

angular.module('walkControl', []).controller(
    'RunExp', ['$compile','$scope','$http','$timeout','$interval','$window','$q', function($compile,$scope,$http,$timeout,$interval,$window,$q) {
    // subject data -- first define
    // with defaults, then use existing
    // for the template repeat
    $scope.formok = false;
    $scope.glob = {
        subject : {
            id:undefined,
            age : undefined,
			gender: undefined,
            height: undefined,
            weight: undefined,
            glasses: undefined,
            dominance: undefined,
            restep_size: undefined,
            shoe_size: undefined,
            regular_sport: "none",
            weekly_minutes: undefined,
            stance_time: undefined
        },
        walks : {
            researcher: "yogev",
            distance: 10,
            number: 12,
            nirs41: Math.random() < 0.5 ? "R" : "L",
            shoe_type: Math.random() < 0.5 ? "normal" : "restep",
            start_time: -1
        },
        single: {
            numtrials: undefined,
            pausetime: undefined
        },
        oldfile : undefined,
        newfile: undefined,
        newSubject: false,
        isSingle : undefined
    };
    
    /** helper vars **/
    $scope.saveFile = undefined;
    $scope.saveSheet = undefined;
    $scope.paramsOk = false;
    $scope.incSaveto = false;
    $scope.numSaves = 0;
    $scope.saveFileExt = ".xlsx";
    $scope.walkTime = 0;
    $scope.countDtime = undefined;
    $scope.reportKeys = [0,1,2,3,4,5,6,7,8,9,'*'];
    $scope.seqEntered = "";
    $scope.incNext = false;
    $scope.nextDisabled = false;
    $scope.srvMessage = "";
    $scope.countDmessage = "";
    $scope.maincontent = "start.html";
    $scope.prewalkText = "";
    $scope.stopper_is_running = false;
    $scope.distractorLength = 6;
    $scope.postWalkDelay = 15;
    $scope.getReadyText = "";
    
    var state = null;
    var stopper = undefined;
    var duration = 0;
    
    var log = {
        globals : {},
        walkdata : [],
        trialdata: [],
        distractions : {},
    };

    // full screen option -- probably won't be used
    $scope.goFull = function() {
    	// Supports most browsers and their versions.
		element = document.body;
    	var requestMethod = element.requestFullScreen || element.webkitRequestFullScreen || element.mozRequestFullScreen || element.msRequestFullScreen;
		// Native full screen.
		if (requestMethod) { 
			requestMethod.call(element);
		} 
 	}
    
    $scope.registerold = function(input) {
        $scope.glob.oldfile = input.value.replace("C:\\fakepath\\","");
        $scope.check_existing();
    }

    $scope.$watch("glob",function(n,v) {
        var checkexisting = false;
        $scope.saveSheet = n.isSingle ? 'single' : n.walks.shoe_type
        // in any case there is no need to check if new
        if(!n.newSubject ) {
            // was new and switched to old:
            if(v.newSubject) {
                checkexisting = true;
                // in this case also clear the newfile filed
                $scope.glob.newfile = undefined;
            }
            // still in old, check again if sheet parameters change
            else {
                checkexisting = n.oldfile != v.oldfile || n.walks.shoe_type != v.walks.shoe_type || n.isSingle != v.isSingle;
            }
        } 
        if(checkexisting) {
            $scope.check_existing();
        }
        if((n.newSubject && n.subject.id != v.subject.id) || (n.newSubject && !v.newSubject)) {
            $scope.ufilename();
        }
        if(n.newSubject) {
            // switched from old to new
            if(!v.newSubject) {
                $scope.glob.isSingle = false;
                $scope.glob.oldfile = undefined;
                $scope.saveFile = undefined;
                $scope.srvMessage = "";
            }
            if(n.newfile != v.newfile) {
                $scope.check_new();
            }
        }
        if(n.isSingle && !v.isSingle) {
            $scope.glob.newSubject = false;
        }
        $scope.checkParams();
    },true);
    
    // primitive form validation
    $scope.checkParams = function() {
        var ok = true,
            id = $scope.glob.subject.id,
            w = $scope.glob.walks;
            s = $scope.glob.subject;
        
        ok = s.id != undefined && s.id != "";
        ok = ok && $scope.saveFile;
        ok = ok && w.nirs41;
        ok = ok && w.researcher != ""; 
        
        if($scope.glob.newSubject) {
            ok = ok && (s.age >= 10) &&  (s.age <= 120);
			ok = ok && s.gender;
            ok = ok && (s.height >= 100) && (s.height <= 250); 
            ok = ok && (s.weight >= 20) && (s.weight <= 150);
            ok = ok && s.glasses;
            ok = ok && s.dominance;
            ok = ok && s.restep_size; 
            ok = ok && (s.shoe_size >= 20) && (s.shoe_size <= 55);
            if(s.regular_sport != "none"){
                ok = ok && (s.weekly_minutes  >= 30) && (s.weekly_minutes <= 1000);
            }
            ok = ok && (s.stance_time >= 0) && (s.stance_time <= 50);
        }
        
        if(!$scope.glob.isSingle) {
            ok = ok && w.distance > 4;
            ok = ok && w.start_time == -1;
        }
         
        $scope.paramsOk = ok;
    }
    
    // make sure existing date doesn't get
    // written over, and in the single task case,
    // that the average duration is there
    $scope.check_existing = function() {
        var f = $scope.glob.oldfile;
        if(f == undefined) {
            $scope.srvMessage = "please select file";
            return;
        }
        var fparts = f.split("."),
            fname = fparts[0],
            fext = fparts[1];
        if(["xlsx","xls","xlsm"].indexOf(fext) < 0) {
            $scope.srvMessage = "please select an Excel file";
        }
        else {
            $scope.srvMessage = "";
            $http({
                url: '/',
                method: "POST",
                headers : {
                    'Content-Type' : 'multipart/form-data'
                },
                data : {
                    command: 'check_existing',
                    filename: $scope.glob.oldfile,
                    savesheet : $scope.saveSheet
                }
            }).then(
                function succ(r) {
                    var d = r.data;
                    $scope.saveFile = $scope.glob.oldfile; 
                    if(d.sheet_status == "exists") {
                        $scope.srvMessage = "The file "+f+" already includes a " + $scope.saveSheet+" sheet. This will write over it.";
                    }
                    if($scope.glob.isSingle) {
                        if(d.error) {
                            $scope.srvMessage = d.error;
                            $scope.saveFile = undefined;
                        }
                        else {
                            $scope.glob.single.numtrials = d.numtrials;
                            $scope.glob.single.pausetime = d.pausetime;
                        }
                    }
                    $scope.checkParams();
                },
                function fail(r) {
                    $scope.srvMessage = "couldn't check the existing file:\n"+r.error;
                    $scope.saveFile = undefined;
                    $scope.checkParams();
                }
            );
        }
        
    };
    
    // update new file name by id
    $scope.ufilename = function() {
        var id = $scope.glob.subject.id;
        $scope.glob.newfile  = id+$scope.saveFileExt;
    };
    
    
    
    // keyboard
	$scope.rpress = function(k) {
        if($scope.reportKeys.indexOf(parseInt(k)) > -1 || k == '*') {
            $scope.seqEntered += k;
        }
        else if(k == 'fixone') {
            $scope.seqEntered = $scope.seqEntered.substring(0,$scope.seqEntered.length - 1);
        }
        else if(k == 'clear') {
            $scope.seqEntered = "";
        }
        else if(k == 'done') {
            if($scope.glob.isSingle) {
                log.trialdata[parseInt(state.trial)].push($scope.seqEntered);
            }
            else {
                log.distractions[state.walk].push($scope.seqEntered);
            }
            $scope.seqEntered = "";
            $scope.next();
        }
        else {
            $scope.srvMessage = "invalid action";
        }
    };
    
    $scope.initialize = function() {
        if(!$scope.glob.isSingle) { 
            state = new stateCycler($scope.glob.walks.number);
            $scope.glob.walks.start_time = Date.now();
        } 
        else {
            state = new singletaskCycler($scope.glob.single.numtrials);
        }
        $scope.srvMessage = "data will be saved to "+$scope.saveFile+"/"+$scope.saveSheet;
        log.globals = $scope.glob; 
        $scope.next();
    }
    
    // validate a new file for saving data
    $scope.check_new = function() {
        var f = $scope.glob.newfile;
        if(!/^[\w\-_\.\(\)]+\.[\d\w]{2,4}$/.test(f)) {
            return;
        }
        $http({
            url: '/',
            method: "POST",
            headers : {
                'Content-Type' : 'multipart/form-data'
            },
            data : {
                command: 'checkfile',
                filename:f             
            }
        }).then(
            function succ(r) {
                var d = r.data;
                $scope.glob.newfile = d.please_saveto;
                $scope.saveFile = d.please_saveto; 
                $scope.checkParams();
            },
            function fail(r) {
                $scope.srvMessage = "couldn't resolve file name:\n"+r.error;

                $scope.checkParams();
            }
        );
    }

    /** button actions **/
    $scope.download = function() {
        if($scope.numSaves < 1) {
            $scope.srvMessage = "nothing to save yet";
            return;
        }
        window.open('http://localhost:8000/download/?file='+$scope.saveFile);
    }
    $scope.terminate = function() {
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
                $scope.srvMessage = r.data.response;
            },
            function fail(r) {
                $scope.srvMessage = "couldn't stop:\n"+r;
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
        if(!state.finished) {
            $scope.countDmessage  =  "click next in ";
            $scope.stopper_countdown(1000,function() {
                $scope.countDmessage  = "";
                $scope.countDtime = undefined;
            },$scope.postWalkDelay*1000);
        }
    }

    $scope.stopper_start = function(step) {
        var walk_start = Date.now();
        var round = Math.floor(Math.log10(1000/step));
        duration = 0;
        $scope.stopper_is_running = true;
        stopper = $interval(function(start,step,r) {
            if($scope.stopper_is_running) {
                duration += step; //must be equal to interval
                $scope.walkTime = frep(duration/1000,r);
            }
            else {
                log.walkdata[state.walk] = [start,start+duration];
                $scope._stopper_stop();
            }
        },step,0,true,walk_start,step,round);
    }
    
    $scope.stopper_countdown = function(step,callback,from) {
        if(from < 0) {
            from = parseInt($scope.glob.single.pausetime);
        }
        var round = Math.floor(Math.log10(1000/step));
        duration = from - (from % step);
        $scope.countDtime = frep(duration/1000,round);
        stopper = $interval(function(s) {
            if(duration >= s) {
                duration -=  s;
                $scope.countDtime = frep(duration/1000,round);
            }
        },step,(duration/step)+1,true,step);
        stopper.then(callback).catch(function(e) {
            console.log(e);
        }).finally(function() {
            stopper = undefined;
        });
    }
    
    
    // save the data
    $scope.save = function() {
        $http.post('/', {
            command: 'save',
            data : log,
            savefile: $scope.saveFile,
            savesheet : $scope.saveSheet
        }).then(
            function succ(r) {
                res = r.data.response;
                if(res == "saved") {
                    $scope.srvMessage = res;
                    $scope.numSaves++;
                }
                else if(res == "failed") {
                    $scope.srvMessage = "couldn't save:\n"+r.data.error;
                }
            },
            function fail(r) {
                $scope.srvMessage(r.data)
            }
        );
    }
    $scope.recloop = function(arr,cur,delay) {
        if(cur == arr.length) {
            $scope.nextDisabled = false;
            $scope.next();
            if($scope.glob.isSingle) {
                $scope.stopper_countdown(50,$scope.next,-1);
            }
            else  {
                $scope.stopper_start(50);
            }
            $scope.distDigit = "";
            return;
        }
        $scope.distDigit = arr[cur];
        cur++;
        $timeout($scope.recloop,delay,true,arr,cur,delay);
    }
    
    $scope.distractor = function(isdist) {
        $scope.nextDisabled = true;
        var digits;
        var dl = $scope.distractorLength;
        if(isdist) {
            digits = randomK(dl,10);
            if($scope.glob.isSingle) {
                log.trialdata.push([digits.join("")]);
            }
            else {
                log.distractions[state.walk] = [digits.join("")];
            }
        }
        else {
            //digits = Array(dl).fill(1).map((x, y) => x + dl - y - 1);
            digits = ['GO','A','B','C','D','E','F','G','H','I','J'].slice(0,dl).reverse();
        }
        $timeout($scope.recloop,2000,true,digits,0,1000);
    }
    
    // the heart of it -- translate the next state
    // to the next display (and/or action)
    $scope.next = function(){
        $timeout(function() {
            $scope.srvMessage = "";
        },2000);
        
        if(state.state == 'prewalk' && state.finished) {
            delete state;
            window.location.replace('http://localhost:8000/wcapp/'); 
            return;
        }
        state.next();
        $scope.prewalkText = "Please prepare subject for"; 
        if(!$scope.glob.isSingle) {
            if(state.next_is_distractor()){
                $scope.prewalkText += " distractor task";
            }
            else {
                $scope.prewalkText += " walk "+(state.walk+2)+" countdown";
            }
        }
        else {
            $scope.prewalkText += " trial "+(state.trial+2);
        }
        if(state.finished) {
            $scope.prewalkText = "The End";
        }
        if(state.state == 'prewalk' && (state.walk >= 0 || state.trial >= 0)) {
            $scope.save();
        }
        $scope.maincontent = state.state+'.html';
        if(state.state == 'digitsboard') {
            $scope.distractor(state.is_distractor());
        }
        if(state.state == 'walk') {
            $scope.nextDisabled = true;
            $scope.walkTime = 0;
        }
        $scope.incNext = ['start','report','digitsboard','trial'].indexOf(state.state) == -1;
        $scope.incSaveto = state.finished && state.state == 'prewalk';
    }
}]);

//.directive('reModel', function () {
//    return {
//		restrict: 'A',
//		compile: function (tElement, tAttrs) {
//			// for some unknown-to-me reason, the input must
//			// be wrapped in a span or div:
//			var tplElement = angular.element('<span><input></span>');
//			var inputEl = tplElement.find('input');
//			inputEl.attr('ng-model', tAttrs.reModel);
//			tElement.replaceWith(tplElement);
//		}
//	};
//}); 
