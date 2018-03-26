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
                if(this.is_distractor()) {
                    this.state = 'distractor';
                }
                else {
                    this.state = 'walk';
                }
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
            case 'distractor':
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

angular.module('walkControl', []).controller(
    'RunExp', ['$compile','$scope','$http','$timeout','$interval','$window', function($compile,$scope,$http,$timeout,$interval,$window) {
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
        savefile: undefined,
        newSubject: true
    };
    //helper vars
    $scope.incSaveto = false;
    $scope.numSaves = 0;
    $scope.saveFileExt = ".xlsx";

    $scope.srvMessage = "";
    $scope.maincontent = "start.html";
        
    $scope.paramsOk = false;
    $scope.prewalkText = "";
    $scope.stopper_is_running = false;
    $scope.walkTime = 0;
    $scope.reportKeys = [0,1,2,3,4,5,6,7,8,9,'*'];
    $scope.seqEntered = "";
    $scope.incNext = false;
    $scope.nextDisabled = false;
    $scope.distractorLength = 5;
    var state = null;
    var stopper = undefined;
    var log = {
        globals : {},
        walkdata : [],
        distractions : {},
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
    $scope.$watch("glob",function(n,v) {
        $scope.checkParams();
    },true);
    $scope.checkParams = function() {
        var ret = true,
            id = $scope.glob.subject.id,
            w = $scope.glob.walks;
            s = $scope.glob.subject;
        ret = s.id != undefined && s.id != "";
        if($scope.glob.newSubject) {
            ret = ret && (s.age > 10) &&  (s.age < 120);
			ret = ret && s.gender;
            ret = ret && (s.height > 100) && (s.height < 250); 
            ret = ret && (s.weight > 20) && (s.weight < 150);
            ret = ret && s.glasses;
            ret = ret && s.dominance;
            ret = ret && s.restep_size; 
            ret = ret && (s.shoe_size > 20) && (s.shoe_size < 55);
            if(s.regular_sport != "none"){
                ret = ret && (s.weekly_minutes  > 30) && (s.weekly_minutes < 1000);
            }
            ret = ret && (s.stance_time > 0) && (s.stance_time < 50);
        }
        ret = ret && w.distance > 4;
        ret = ret && w.nirs41;
        ret = ret && w.researcher != ""; 
        ret = ret && /^[\w\-_\.\(\)]+\.[\d\w]{2,4}$/.test($scope.glob.savefile);
        ret = ret && $scope.glob.walks.start_time == -1;

        $scope.paramsOk = ret;
    }

    $scope.check_existing = function(input) {
        if(typeof(input) == "object") {
            fparts  = input.value.replace("C:\\fakepath\\","").split(".");
        }
        else {
            fparts = input.split(".");
        }
        donechecked = false;
        fname = fparts[0];
        fext = fparts[1];
        f = fname+"."+fext;
        if(["xlsx","xls","xlsm"].indexOf(fext) < 0) {
            $scope.glob.savefile = "";
            $scope.srvMessage = "please select an Excel file";
        }
        else if($scope.glob.subject.id == undefined || $scope.glob.subject.id == "") {
            $scope.srvMessage = "Please Identify Subject";
            input.value = "";
            $scope.glob.savefile = "";
        }
        else {
            $scope.glob.savefile = f;
            donechecked = true;
            $scope.srvMessage = "";
            $http({
                url: '/',
                method: "POST",
                headers : {
                    'Content-Type' : 'text/html'
                },
                data : {
                    command: 'check_existing',
                    filename: $scope.glob.savefile,
                    sheet : $scope.glob.walks.shoe_type
                }
            }).then(
                function succ(r) {
                    if(r.data == "exists") {
                        $scope.srvMessage = "The file "+f+" already includes a " + $scope.glob.walks.shoe_type+" sheet. This will write over it.";
                    }
                    $scope.glob.savefile = f;
                    $scope.glob.newSubject = false;
                },
                function fail(r) {
                    $scope.srvMessage = "couldn't check the existing file";
                }
            );
        }
        if(!donechecked) {
            $scope.$apply();
        }
    };
    
    $scope.ufilename = function() {
        var id = $scope.glob.subject.id;
        $scope.glob.savefile  = id+$scope.saveFileExt;
    };
    $scope.clearfile = function() {
        $scope.srvMessage = "";
        $scope.glob.savefile = "";
        $scope.glob.newSubject = true;
        if($scope.glob.subject.id) {
            $scope.ufilename();
        }
    }

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
            log.distractions[state.walk].push($scope.seqEntered);
            $scope.seqEntered = "";
            $scope.next();
        }
        else {
            $scope.srvMessage = "invalid action";
        }
    };
    
    $scope._init = function() {
        $scope.srvMessage = "data will be saved to "+$scope.glob.savefile+"/"+$scope.glob.walks.shoe_type;
        log.globals = $scope.glob; 
        log.globals.walks.start_time = Date.now();
        $scope.next();
    };
    $scope.initialize = function(n) {
        $scope.glob.walks.number = angular.copy(n)
        state = new stateCycler(n);
        if($scope.glob.subject.id < 1) {
            $scope.srvMessage = "Please Enter Identifier";
            delete state;
            return;
        }
         
        if(!$scope.glob.newSubject) {
            $scope._init();
            return;
        }
        $http({
            url: '/',
            method: "POST",
            headers : {
                'Content-Type' : 'text/html'
            },
            data : {
                command: 'checkfile',
                filename: $scope.glob.savefile
            }
        }).then(
            function succ(r) {
                $scope.glob.savefile = r.data;
                $scope._init();
            },
            function fail(r) {
                $scope.srvMessage = "couldn't resolve file name";
            }
        );
    }

    $scope.download = function() {
        if($scope.numSaves < 1) {
            $scope.srvMessage = "nothing to save yet";
            return;
        }
        window.open('http://localhost:8000/download/?file='+$scope.glob.savefile);
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
            $scope.next();
            $scope.stopper_start();
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
        },2000);
        
        if(state.state == 'prewalk' && state.finished) {
            delete state;
            window.location.replace('http://localhost:8000/wcapp/'); 
            return;
        }
        state.next();
        if(state.next_is_distractor()){
            $scope.prewalkText = "Please prepare subject for distractor task";
        }
        else{
            if(!state.finished) {
                $scope.prewalkText = "walk "+(state.walk+1)+" is starting";
            }
            else {
                $scope.prewalkText = "The End";
            }
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
        $scope.incNext = ['start','report','distractor'].indexOf(state.state) == -1;
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
