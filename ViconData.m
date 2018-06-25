classdef ViconData
    %VICONDATA helper functions class
    %   concentrates various helper functions used by the stick
    %   figures script
    properties
        extras
        datarate
        tarfile
        splitsdir
        condition
        savefolder
        fixed
        mutables
        subjname
        distract
        numperts
        resource_base
        trajcolumns
    end
    
    methods(Static)
        function [Rightarms,Leftarms] = findArms(left,right)
            leftStart = find(abs(left(31:end) - left( 1:end -30))>50, 1);    
            rightStart = find(abs(right(31:end) - right( 1:end -30))>50, 1);
            if isempty(leftStart) && isempty(rightStart)
                Rightarms(1:2) =-5000;
                Leftarms(1:2) =-5000;
            elseif isempty(leftStart) && ~isempty(rightStart)
                Rightarms(1) = rightStart;
                Leftarms(1:2) =-5000;
                %  leftEnd = find(abs(left(arms(1) +  31:end) - left(arms(1)+ 1:end -30))<5, 1, 'last');
                rightEnd = find(abs(right(Rightarms(1) +  31:end) - right(Rightarms(1) + 1:end -30))>50, 1, 'last');
                Rightarms(2) = Rightarms(1) + rightEnd;
            elseif ~isempty(leftStart) && isempty(rightStart)
                Leftarms(1) = leftStart;
                Rightarms(1:2)=-5000;
                leftEnd = find(abs(left(Leftarms(1) +  31:end) - left(Leftarms(1)+ 1:end -30))>50, 1, 'last');
                %  rightEnd = find(abs(right(arms(1) +  31:end) - right(arms(1) + 1:end -30))<5, 1, 'last');
                Leftarms(2) = Leftarms(1) + leftEnd;
            else
                Rightarms(1) = rightStart;
                Leftarms(1) = leftStart;
                leftEnd = find(abs(left(Leftarms(1) +  31:end) - left(Leftarms(1)+ 1:end -30))>40, 1, 'last');
                rightEnd = find(abs(right(Rightarms(1) +  31:end) - right(Rightarms(1) + 1:end -30))>40, 1, 'last');
                Rightarms(2) =Rightarms(1) + rightEnd;
                Leftarms(2) =Leftarms(1) + leftEnd;
            end
        end
    
        function cgOut = isOutOf(upperbound,lowerbound,target)
            % Retrieve the range of read points in which target is outside the
            % bounds. For ML perturbations, the bounds are left and right ankles,
            % **right is the lower one**. on the X dimension of  course.
            % For AP perturbations, the bounds are min(left_toe,right_toe)
            % for **lower** bound and max(left_heel,right_heel) **for upper** on
            % Y. The target of interest in both cases is the CG (x,y
            % respectively). Note that both left/right and forward/backward
            % are reversed!
            
            ustart = find(target > upperbound,1);
            lstart = find(target < lowerbound,1);

            % no divergence found
            if isempty(ustart) && isempty(lstart)
                cgOut = [-5000,-5000];
                return;
            end

            % if there was an upperbound breach, it ends where 
            % the oposite condition holds
            if ~isempty(ustart)
                uend = find(target(ustart:end) <= upperbound(ustart:end),1);
            end
            
            % same for lower bound
            if ~isempty(lstart)
                lend = find(target(lstart:end) >= lowerbound(lstart:end),1);
            end

            % return the start and finish indices of the earliest breach
            if isempty(ustart) || (~isempty(lstart) && lstart < ustart)
                outStart = lstart;
                outEnd = lend;
            elseif isempty(lstart) || (~isempty(ustart) && ustart < lstart)
                outStart = ustart;
                outEnd = uend;
            end
            cgOut = [outStart,outStart + outEnd];
        end
        
        function perts = findMLpert(bmprx)
            % returns [start end] pairs of ML perturbations 
            thresh = 5; 
            step = 100;
            % center the data
            bmprx = abs(bmprx) - mean(abs(bmprx(1:250)));
            
            % identify the perturbations
            [peaks,inds] = findpeaks(bmprx,'MinPeakDistance',1000,'MinPeakHeight',15);

            perts = zeros(length(peaks),2);
            for i = 1:size(perts,1)
                % scan backwards to find the start
                cur = inds(i);
                while mean(bmprx(cur - step:cur)) > thresh
                    cur = cur - step;
                end
                start = cur - step/2;
                % scan forward to find the end
                cur = inds(i);
                while mean(bmprx(cur:cur + step)) > thresh
                    cur = cur + step;
                end
                finish = cur + step/2;
                perts(i,:) = [start,finish];
            end
        end

        function perts = findAPpert(ankley,mlperts)
            % given the ankle position and the set of
            % ML perturbations, finds the AP pertrubations
            % in bwetween
            thresh = 0.2;
            step = 50; 
            trim = 500;
            % it's clearer to look at the absolute value of
            % the diff vector
            subj = abs(diff(ankley));
            for i = 0:size(mlperts,1) - 1
                % set the range
                if i == 0
                    segstart = 1;
                else
                    % end point of ML perturbation
                    segstart = mlperts(i,2);
                end
                % we can safely reduce the search span
                % by 500 reads
                segstart = segstart + trim; 
                % start point of next ML perturbation
                segfinish = mlperts(i+1,1) - trim;
                % find first high enough peak indices are relative to this
                % part of the subj vector!
                [~,inds] = findpeaks(subj(segstart:segfinish),'MinPeakHeight',thresh,'MinPeakDistance',step);
                % scan back to find the perturbation start
                cur = inds(1);
                while mean(subj(segstart + cur - step:segstart + cur)) > thresh
                    cur = cur - step;
                end
                start = cur - step/2;
                % scan forward
                cur = inds(1);
                while mean(subj(segstart + cur:segstart + cur+step)) > thresh
                    cur = cur + step;
                end
                finish = cur + step/2;
                perts(i+1,:) = [segstart + start,segstart + finish];
            end
        end
    end
    methods
        function self = ViconData(targetfile)
            %VICONDATA construct an instance from file
            %   Detailed explanation goes here
            [p,b,~] = fileparts(targetfile); % path basename extension
            self.savefolder = fullfile(p,b);
            self.tarfile = targetfile;
            self.numperts = 0;
            self.fixed = struct;
            self.mutables = struct;
            self.subjname = strip(regexprep(b,'(walk|stand).*','','ignorecase'));
            self.splitsdir = 'splits';
            c = regexpi(targetfile,'(walk|stand)','match');
            distract = regexp(b,'(ST|DT).*$','match');
            self.condition = lower(c{1});
            self.resource_base = b;
            self.distract = distract;
            self.extras = {'datarate','numperts','trajcolumns'};
        end
        
        function file_location = dataparts(self,part)
            assert(strcmp('trajectories',part) || strcmp('model',part),'data parts name is either "trajectories" or "model"');
            [p,f,e] = fileparts(self.tarfile);
            file_location = fullfile(p,self.splitsdir,[f '-' part e]);
        end
                       
        function file_location = dloc(self,loc)
            b = replace(self.resource_base, ' ','_');
            file_location = fullfile(self.savefolder,[loc b '.mat']);
        end
        
        function self = LoadData(self)
            % set the fixed (Vdata) and mutable (Vdata2) structs
            % read from disk if exist, compute if missing
            d1 = struct;
            d2 = struct;
            atts = struct;
            if isdir(self.savefolder) 
                loc1 = self.dloc('Vdata');
                loc2 = self.dloc('Vdata2');
                loc3 = self.dloc('VcdAtts');
                if exist(loc1,'file')
                    d1 = load(loc1);
                end
                if exist(loc2,'file')
                    d2 = load(loc2);
                end
                if exist(loc3,'file')
                    atts = load(loc3);
                end
            end
            if ~(isempty(fieldnames(d1)) || isempty(fieldnames(d2)))
                self.fixed = d1.f;
                self.mutables = d2.m;
                saved = fieldnames(atts.props);
                for i=1:length(saved)
                    self.(saved{i}) = atts.props.(saved{i});
                end
                return;
            end
            
            
            % data rate,column names, and data of first block -- the model outputs
            [r,acolumns,model] = self.dBlock('model');
            
            % Angles of Elbow and Shoulder [R L]
            LElbowAng=model(:,self.cellindex(acolumns,'LElbowAngles')); % just the x angle
            lsind = self.cellindex(acolumns,'LShoulderAngles');
            LShoulderAng=model(:,lsind:lsind+2); % all three
            RElbowAng=model(:,self.cellindex(acolumns,'RElbowAngles'));
            rsind = self.cellindex(acolumns,'RShoulderAngles');
            RShoulderAng=model(:,rsind:rsind+2);
            
            % rate,columns and data of second block -- marker trajectories 
            [drate,bcolumns,traj] = self.dBlock('trajectories');

            assert(r{:} == drate{:}, 'data rate missmatch');
            self.datarate = drate{:};
            self.trajcolumns = bcolumns;

            function [lcols,rcols] = left_and_right(colbase)
                % returns the column vector corresponding to the left and right [x y z ]
                % vectors of "base"
                left = self.cellindex(bcolumns,['L' colbase]);
                right = self.cellindex(bcolumns,['R' colbase]);
                lcols = traj(:,left:left+2);
                rcols = traj(:,right:right+2);
                if nargin == 2
                    lcols = lcols - bamperDisplacement;
                    rcols = rcols - bamperDisplacement;
                end
            end

            
            % find [ x y  z ] coordinate of the left bumper-marker
            bamper = self.cellindex(bcolumns,'bamperL');  
            bamperDisplacement = traj(:,bamper:bamper+2) - traj(1,bamper:bamper+2);    
            
            
            % ankles,heels toes, arm
            [leftAnkle,rightAnkle]  = left_and_right('ANK');
            [leftHeel,rightHeel] = left_and_right('HEE');
            [leftToe,rightToe] = left_and_right('TOE');
            [leftArm,rightArm] = left_and_right('FIN');
            
            % Center of Mass
            model(:,3)  = model(:,3) - bamperDisplacement(:,1); %cgx
            
            perTimesML = ViconData.findMLpert(bamperDisplacement(:,1));   %lateral
            self.numperts = size(perTimesML,1);
            
            if strcmp(self.condition,'stand')
                perTimesAP = ViconData.findAPpert(leftAnkle(:,2),perTimesML); % anterior-posterior
                self.numperts = self.numperts + size(perTimesAP,1);
            end
            
            %%%%%%%%%%%%%%%%%%%
            for pind=1:length(perTimesML)+length(perTimesAP)
                if exist('perTimesAP','var')
                    register_pert(pind,1);
                end
                register_pert(p,2);
            end
            
            self.fixed = d1;
            self.mutables = d2;
            
            if ~isdir(self.savefolder)
                mkdir(self.savefolder);
            end
            
            self.savedata();

            function register_pert(perturbation_index,perturbation_type)
                % perturbation_type, 1: AP, 2: ML
                p = perturbation_index;
                if perturbation_type == 1
                    times = perTimesAP;
                else
                    times = perTimesML; 
                end
                twosec = double(2*self.datarate);
                segment_start =  times(p,1) - twosec;
                segment_end = times(p,2) + 3*self.datarate; 
                trange = segment_start:segment_end;
                lAnkleX = leftAnkle(trange,1);
                rAnkleX = rightAnkle(trange,1);
                lHeelY = leftHeel(trange,2);
                lToeY = leftToe(trange,2);
                rHeelY = rightHeel(trange,2);
                rToeY= rightToe(trange,2);
                leftArmX = leftArm(:,1);
                rightArmX = rightArm(:,1);
                CG = model(trange,3:5);
                CG_Orig = CG;
 
            
                % stepping is in x and y plane
                if strcmp(self.condition,'stand')
                    leftStepping = vecnorm(leftAnkle(trange,1:2)')'; %+(leftAnkleZ(timeSlot(1):timeSlot(2))).^2);
                    rightStepping = vecnorm(rightAnkle(trange,1:2)')'; %+(rightAnkleZ(timeSlot(1):timeSlot(2))).^2);              
                    % bias to zero
                    leftStepping = leftStepping - leftStepping(1);
                    rightStepping = rightStepping - rightStepping(1);

                %% why?!?!
                else
                    leftStepping = lAnkleX - lAnkleX(1);
                    rightStepping = rAnkleX - rAnkleX(1);
                end 


                % arms movement is in x y z plane and the ??cg?? is reduced
                if strcmp(self.condition,'stand')
                    leftArmTotal = vecnorm((leftArm(trange,:) - CG)')';
                    rightArmTotal = vecnorm((rightArm(trange,:) - CG)')';
                % why?!?!
                else
                    leftArmTotal = leftArmX(trange) - CG(:,1);
                    rightArmTotal = rightArmX(trange) - CG(:,1);
                end
                leftArmTotal = leftArmTotal - leftArmTotal(1);
                rightArmTotal = rightArmTotal - rightArmTotal(1);
                
                % find first step foot, last step foot, and the stepping time
                % from perturbations
                [steppingTime, firstStep,EndFirstStep, lastStep] = self.findStepping(leftStepping(twosec+1:end), rightStepping(twosec+1:end));
                steppingTime = 240 + steppingTime; % add the 2 seconds before the perturbation
                
                % find arms movement from perturbation
                if strcmp(self.condition,'stand')
                    [RightarmsTime,LeftarmsTime] = ViconData.findArms(leftArmTotal(twosec+1:end), rightArmTotal(twosec+1:end));
                else
                    shifted = twosec + segment_start:segment_end;
                    [RightarmsTime,LeftarmsTime] = ViconData.findArms(leftArmX(shifted),rightArmX(shifted));%check only movement in x direction
                end
                RightarmsTime=RightarmsTime+twosec; 
                LeftarmsTime=LeftarmsTime+twosec;
                lAnkleX = lAnkleX - CG(1,1);
                rAnkleX = rAnkleX - CG(1,1);
                lHeelY = lHeelY - CG(1,2);
                rToeY= rToeY - CG(1,2);
                rHeelY = rHeelY - CG(1);
                lToeY= lToeY - CG(1);
                CG = CG - CG(1,:);
               
                
                %find when CG is out of legs
                if perturbation_type == 2
                    cgOut = ViconData.isOutOf(lAnkleX,rAnkleX,CG(:,1));
                else % front or back pertubation
                    cgOut = ViconData.isOutOf(max(lToeY,rToeY),min(lHeelY,rHeelY),CG(:,2));
                end
                % finally, update the two structs
                d1(p).bamper = bamperDisplacement(trange);
                d1(p).leftAnkleX = lAnkleX;
                d1(p).rightAnkleX = rAnkleX;
                d1(p).leftStepping = leftStepping;
                d1(p).rightStepping = rightStepping;
                d1(p).CGX = CG(:,1);
                d1(p).CGX_plot=CG_Orig(:,1); 
                d1(p).CGY = CG(:,2);
                d1(p).CGY_plot=CG_Orig(:,2);
                d1(p).CGZ = CG(:,3);
                d1(p).CGZ_plot=CG_Orig(:,3);
                d1(p).leftToeY=lToeY;
                d1(p).leftHeelY =lHeelY;
                d1(p).rightToeY=rToeY;
                d1(p).rightHeelY =rHeelY;
                d1(p).leftArmTotal = leftArmTotal;
                d1(p).rightArmTotal = rightArmTotal;
                d1(p).name = self.subjname;
                d1(p).step = self.resource_base;
                d1(p).pertubationsTime = times(p);
                d1(p).steppingTime = steppingTime;
                d1(p).firstStep = firstStep;
                d1(p).EndFirstStep = EndFirstStep+twosec;         
                d1(p).lastStep = lastStep;
                d1(p).RightarmsTime = RightarmsTime;
                d1(p).LeftarmsTime = LeftarmsTime;
                d1(p).edited = false;
                d1(p).cgOut = cgOut;
                d1(p).TypeArmMove=[];
                d1(p).TypeLegMove=[];
                d1(p).Fall=0;
                d1(p).MS=0;%multiple steps
                d1(p).SFdATA = traj(trange,3:end);
                d1(p).StringPer=num2str(p);
                d1(p).LElbowAng=LElbowAng(trange);
                d1(p).LShoulderAng=LShoulderAng(trange,1:3);       
                d1(p).RElbowAng=RElbowAng(trange);
                d1(p).RShoulderAng=RShoulderAng(trange,1:3); 
                % mutables ("Vdata2")
                mutfields = {'pertubationsTime','steppingTime','firstStep',...
                    'EndFirstStep', 'lastStep','RightarmsTime','LeftarmsTime',...
                    'cgOut','TypeArmMove','TypeLegMove','Fall','MS'
                };
                for field=mutfields
                    d2(p).(field{:}) = d1.(field{:});
                end
            end 
        end
        
        function savedata(self)
            f = self.fixed; %#ok<NASGU>
            m = self.mutables; %#ok<NASGU>
            save(self.dloc('Vdata'),'f');
            save(self.dloc('Vdata2'),'m');
            props = struct;
            for f=self.extras
                props.(f{:}) = self.(f{:});
            end
            save(self.dloc('VcdAtts'),'props');
        end
        
        function [ind] = cellindex(self,cells,item)
            ind = find(strcmp(cells,[self.subjname ':' item]) == 1);
        end

        function [r,cols,dat] = dBlock(self,part)
            % see if the part file exists
            tar = self.dataparts(part);
            
            if ~exist(tar,'file')
                try
                    disp('calling the split');
                    [p,~,~] = fileparts(self.tarfile);
                    splitter = fullfile(p,'pws.ps1');
                    system(['powershell -inputformat none -file ' splitter]);
                catch e
                    disp(e);
                    return;
                end
            end
           
            % reads the subsequent column names, datarate and
            % numeric matrix from the instance file.
            f = fopen(tar);
            
            % scan for 'Frame,Sub Frame...' 
            tline = '';
            linecount = 0;
            while ~startsWith(tline,'Frame')
                tline = fgetl(f);
                linecount = linecount + 1;
            end
            
            % rate is 2 above
            fseek(f,0,-1);
            r = textscan(f,'%d',1,'delimiter','\n','headerlines',max(0,linecount - 3));

            % columns row is 1 above the line that starts with 'Frame'
            fseek(f,0,-1);
            cline = textscan(f,'%s',1,'delimiter','\n','headerlines',linecount - 2);
            cols = split(cline{:},',');
            fclose(f);
            
            % data is two below that line, and to the end            
            d =  importdata(tar, ',',linecount + 1);
            dat = d.data;
            %dat = dlmread(tar,',',linecount+1,0);
        end
        
        function [stepping,firstStep,EndFirstStep,lastStep] = findStepping(self,left,right)
            firstStep = 0;
            lastStep = 0;
            if strcmp(self.condition,'walk')
                VelocityL=(left(2:end)-left(1:end-1))*self.datarate;
                VelocityR=(right(2:end)-right(1:end-1))*self.datarate;
                AccL=(VelocityL(2:end)-VelocityL(1:end-1))*self.datarate;
                AccR=(VelocityR(2:end)-VelocityR(1:end-1))*120;
                leftStart = find(abs(AccL( 11:end) - AccL( 1:end -10))>0.9*120*120, 1, 'first');    
                rightStart = find(abs(AccR( 11:end) - AccR( 1:end -10))>0.9*120*120, 1, 'first');
    
                if isempty(leftStart) && isempty(rightStart)
                    stepping(1:2) =-5000;
                    EndFirstStep=-5000;
                elseif isempty(leftStart) && ~isempty(rightStart)
                    stepping(1) = rightStart;
                    rightEnd = find(abs(AccR(stepping(1) +  11:end) - AccR(stepping(1) + 1:end -10))<0.01*120*120, 1, 'first');
                    EndFirstStep = stepping(1) + rightEnd;
                    firstStep =1;
                    lastStep = 1;
                    %[pks,locs] = findpeaks(AccR(stepping(1):stepping(2)));
                    [pks,locs] = findpeaks(AccR(EndFirstStep:end));
                    index=find(pks>0.4*120*120,1,'last');
                    if isempty(locs) ||isempty(index )
                        stepping(2)=EndFirstStep;
                        %[pks,locs] = max(AccR(stepping(1):stepping(2)))
                    else
                        %EndFirstStep=locs(1)+stepping(1);
                        index=find(pks>0.4*120*120,1,'last');
                        stepping(2)=locs(index)+EndFirstStep;
                    end
                elseif ~isempty(leftStart) && isempty(rightStart)
                    stepping(1) = leftStart;
                    leftEnd = find(abs(AccL(stepping(1) +  11:end) - AccL(stepping(1)+ 1:end -10))<0.01*120*120, 1, 'first');
                    EndFirstStep = stepping(1) + leftEnd;
                    firstStep =2;
                    lastStep = 2;
                    %[pks,locs] = findpeaks(AccL(stepping(1):stepping(2)));
                    [pks,locs] = findpeaks(AccL(EndFirstStep:end));
                    index=find(pks>0.4*120*120,1,'last');
                    if isempty(locs) ||isempty(index )
                        stepping(2)=EndFirstStep;
                        %[pks,locs] = max(AccL(stepping(1):stepping(2)))
                    else
                        index=find(pks>0.4*120*120,1,'last');
                        stepping(2)=locs(index)+EndFirstStep;
                    end

                else
                    stepping(1) = min(leftStart, rightStart);
                    leftEnd = find(abs(AccL(stepping(1) +  11:end) - AccL(stepping(1)+ 1:end -10))<0.01*120*120, 1, 'first');
                    rightEnd = find(abs(AccR(stepping(1) +  11:end) - AccR(stepping(1) + 1:end-10 ))<0.01*120*120, 1, 'first');
                    EndFirstStep =stepping(1) + max(leftEnd, rightEnd);
                    if(leftStart >rightStart)
                        firstStep =1;%right first
                        [pks,locs] = findpeaks(AccR(EndFirstStep:end));
                        index=find(pks>0.4*120*120,1,'last');
                        if isempty(locs) ||isempty(index )
                         stepping(2)=EndFirstStep;
                        %[pks,locs] = max(AccR(EndFirstStep:end))
                        else
                            index=find(pks>0.4*120*120,1,'last');
                             stepping(2)=locs(index)+EndFirstStep;
                        end
                    else
                        firstStep =2;%left first
                        [pks,locs] = findpeaks(AccL(EndFirstStep:end));
                        index=find(pks>0.4*120*120,1,'last');
                        if isempty(locs) ||isempty(index )
                            stepping(2)=EndFirstStep;
                            %[pks,locs] = max(AccL(stepping(1):stepping(2)))
                        else
                            index=find(pks>0.4*120*120,1,'last');
                            stepping(2)=locs(index)+EndFirstStep;
                        end
                    end

                    if leftEnd >= rightEnd
                        lastStep = 2;% left last
                    else
                        lastStep = 1;%right last
                    end
                end
            end
            if strcmp(self.condition,'stand')
                x = find(abs(left-right)>7, 1, 'first');  
                y = find(abs(left-right)>7, 1, 'last');
                if isempty(x) 
                    stepping(1:2) =-5000;
                    EndFirstStep=-5000;
                else
                    stepping(1)=x;
                    stepping(2)=find(abs(left-right)>7, 1, 'last'); 
                    if(left(x) > right(x))
                        firstStep =2; % left first
                        [~,locs] = findpeaks(left(stepping(1):stepping(2)));
                        if isempty(locs)
                            [~,locs] = max(left(stepping(1):stepping(2)));
                        end
                        EndFirstStep=locs(1)+stepping(1);
                    else
                        firstStep =1; % right first
                        [~,locs] = findpeaks(right(stepping(1):stepping(2)));
                        if isempty(locs)
                            [~,locs] = max(right(stepping(1):stepping(2)));
                        end
                        EndFirstStep=locs(1)+stepping(1);
                    end
                    if(left(y) > right(y))
                        lastStep =2; % left last
                    else
                        lastStep =1; % right last
                    end
                end
            end
        end
    end
end
