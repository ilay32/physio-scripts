classdef ViconData
    %VICONDATA helper functions class
    %   concentrates various helper functions used by the stick
    %   figures script
    properties(Constant)
       stick_figure_markers = {...
        {'LFHD','RFHD'},... % left forhead - right forehead
        {'LFHD','LBHD'},... % left forhead - left backhead
        {'RBHD','RFHD'},... % right backhead - right forehead 
        {'RBHD','LBHD'},... % right backhead - left backhead
        {'CLAV','LSHO'},... % clavicula - left shoulder  
        {'CLAV','RSHO'},... % clavicula - right shoulder 
        {'LSHO','LELB'},... % left shoulder - left elbow 
        {'LWRA','LELB'},... % left wrist A - left elbow 
        {'LWRB','LELB'},... % left wrist B - left elbow 
        {'LWRA','LFIN'},... % left wrist A - left FIN 
        {'LWRB','LFIN'},... % left wrist B - left FIN 
        {'RSHO','RELB'},... % right shoulder - right elbow    
        {'RWRA','RELB'},... % right wrist A - right elbow 
        {'RWRB','RELB'},... % right wrist B - right elbow 
        {'RWRA','RELB'},... % right wrist A - right FIN 
        {'RWRB','RFIN'},... % right wrist B - right FIN 
        {'LASI','RASI'},... % left asis - right asis
        {'LASI','LPSI'},... % left asis - left PSI
        {'RPSI','RASI'},... % right PSI - right asis   
        {'RPSI','LPSI'},... % right PSI - left PSI 
        {'LASI','LKNE'},... % left asis - left knee 
        {'LANK','LKNE'},... % left ankle - left knee  
        {'LANK','LHEE'},... % left ankle - left heel 
        {'LANK','LTOE'},... % left ankle - left toe    
        {'LHEE','LTOE'},... % left heel - left toe 
        {'RASI','RKNE'},... % right asis - right knee
        {'RANK','RKNE'},... % right ankle - right knee 
        {'RANK','RHEE'},... % right ankle - right heel 
        {'RANK','RTOE'},... % right ankle - right toe 
        {'RHEE','RTOE'},... % right heel - right toe 
        {'bamperR','bamperL'},... % bamper
    };
    end
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
        protocol
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
        
        function outtime = isOutOf(upperbound,lowerbound,target)
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
                outtime = [-5000,-5000];
                return;
            end

            % if there was an upperbound breach, it ends where 
            % the oposite condition holds
            if ~isempty(ustart)
                uend = min(find(target(ustart:end) <= upperbound(ustart:end),1),length(target));
            end
            
            % same for lower bound
            if ~isempty(lstart)
                lend = min(find(target(lstart:end) >= lowerbound(lstart:end),1),length(target));
            end

            % return the start and finish indices of the earliest breach
            if isempty(ustart) || (~isempty(lstart) && lstart < ustart)
                outStart = lstart;
                outEnd = lend;
            elseif isempty(lstart) || (~isempty(ustart) && ustart < lstart)
                outStart = ustart;
                outEnd = uend;
            end
            outtime = [outStart,outStart + outEnd];
        end
    end
    methods
        function self = ViconData(targetfile)
            %VICONDATA construct an instance from file
            %   Detailed explanation goes here
            [p,b,~] = fileparts(targetfile); % path basename extension
            self.savefolder = fullfile(p,['new_' strrep(b,' ','_')]);
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
            self = self.read_protocol();
        end
        function [stepping,firstStep,EndFirstStep,lastStep] = findStepping(self,left,right)
            firstStep = 0;
            lastStep = 0;
            if strcmp(self.condition,'walk')
                VelocityL=diff(left)*self.datarate;
                VelocityR=diff(right)*self.datarate;
                AccL=diff(VelocityL)*self.datarate;
                AccR=diff(VelocityR)*120;
                leftStart = find(abs(AccL(11:end) - AccL( 1:end -10))>0.9*120*120, 1, 'first');    
                rightStart = find(abs(AccR(11:end) - AccR( 1:end -10))>0.9*120*120, 1, 'first');
    
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
        function perts = findMLpert(self,bmprx)
            % returns [start end] pairs of ML perturbations
            mph = 20; % that's 2cm of bamper movement, could be read from protocol too...
            scanwindow = 10;
            % center the data around the first few seconds according to
            % protocol, and set some findpeaks parameters
            if ~isempty(self.protocol)
                safelyzero = round(self.protocol(1)*self.datarate/2);
                mpd = round(mean(diff(self.protocol*self.datarate))/3);
            else
                safelyzero = 2*self.datarate;
                mpd = 1000;
            end
            bmpsd = std(bmprx(1:safelyzero));
            bmprx = bmprx - mean(bmprx(1:safelyzero));
            
            % identify the perturbations
            [peaks,inds] = findpeaks(abs(bmprx),'MinPeakDistance',mpd,'MinPeakHeight',mph);

            perts = zeros(length(peaks),2);
            for i = 1:size(perts,1)
                % identify the movement start as the first place where
                % there is significant, continuous movement in the
                % direction of the perturbation (it tends to move slighty
                % to the other side first).
                side = sign(bmprx(inds(i)));
                cur = inds(i);
                while mean(abs(bmprx(cur - scanwindow:cur))) > bmpsd && all(sign(bmprx(cur-scanwindow:cur)) == side) 
                    cur = cur - scanwindow;
                end
                start = cur - scanwindow;
                % scan forward to find the end
                %cur = inds(i);
                %while mean(bmprx(cur:min(cur + step,length(bmprx)))) > thresh
                %    cur = cur + step;
                %end
                %finish = cur + step/2;
                %perts(i,:) = [start,finish];
                perts(i,:) = [start,inds(i)];
            end
        end
        function perts = findAPpert(self,ank,mlperts,useprot)
            % given the ankle position and the set of
            % ML perturbations, finds the AP pertrubations
            % in bwetween. if the protocol is usable, take the protocol points and verify 
            % with ank, otherwise, just use the ank peaks.
            % ank: sum of absolute y location of left and right ankle
            % mlperts: perturbations identified by bamper movement. row : [start
            % finish]
            % in any event, the joined list of perturbation times is returned.
            perts = [];
            protml = self.protocol(2:2:end)*self.datarate;
            protap = self.protocol(1:2:end)*self.datarate;
            protlag = mean(protml(1:length(mlperts)) - mlperts(:,1));

            % it's clearer to look at the absolute value of
            % the diff vector of ank
            dank = abs(diff(ank));
            ank_low = nanmean(dank);
            ank_min_peak = nanmean(dank)+nanstd(dank);
            maxpertduration = self.datarate/2; % half a second limit on duration of perturbation
            space = round(mean(diff(mlperts(:,1))/3)); % third of the difference between ML perturbations
            bankwindow = 6; % since these are diffs, we can scan tightly backwards 
            fankwindow = round(self.datarate/5); % ask Inbal, what is the significance of this.
            for i = 0:size(mlperts,1)
                if i == length(protap)
                    break;
                end
                % set the range in which to search
                if useprot
                    % if the protocol is good, set the start to  some lags
                    % before the current AP point stated in the protocol
                    segstart = protap(i+1) - bankwindow*abs(protlag); 
                else
                    % no protocol to work with, use found ML perturbation
                    % times.
                    % if it's the first
                    if i == 0
                        segstart = 1;
                    else
                        % end point of ML perturbation + minimal safe space
                        segstart = mlperts(i,2) + space;
                    end                    
                end
                % it might be finished already
                if segstart > length(dank)
                    break;
                end
                
                % set the segment end
                if useprot
                    % if we're in the last ML and the data ends before the
                    % next AP, the segment will end with the data
                    segfinish = min(protml(i+1) - space,length(dank));
                else
                    if i < size(mlperts,1)
                        % not last ML, no problem
                        segfinish = min(mlperts(i+1,1) - space,length(dank));
                    else
                        % last ML, protocol unusable -- take end of last ML
                        % + space or the end of the data as end
                        segfinish = min(segstart + space,length(dank));
                    end
                end
                segstart = round(segstart);
                segfinish = round(segfinish);
                
                % if there's too many NaNs or the segment is too short, skip it. hopefully this will happen
                % only in the last ML to end case, where this last stretch
                % is no good for analysis.
                if (sum(isnan(dank(segstart:segfinish))) > (segfinish-segstart)/2) || (segfinish - segstart < 3)
                    continue;
                end
                % find first high enough peak indices in the current segment
                [~,inds] = findpeaks(dank(segstart:segfinish),'MinPeakHeight',ank_min_peak);
                
                % scan back to find the perturbation start
                cur = inds(1);
                while mean(dank(segstart + cur - bankwindow:segstart + cur)) > ank_low
                    cur = cur - bankwindow;
                end
                start = round(cur - bankwindow/2);
                if useprot
                    start = start + round((protap(i+1) - protlag - start - segstart)/2);
                end
                % scan forward
                cur = inds(1);
                while mean(dank(segstart + cur:segstart + cur + fankwindow)) > ank_low
                    cur = cur + fankwindow;
                    if cur - inds(1) > maxpertduration
                        break;
                    end
                end
                % inds is relative to segstart so:
                finish = cur + round(fankwindow/2);
                perts(end+1,:) = [segstart + start,segstart + finish];
                if i+1 <= size(mlperts,1)
                    perts(end+1,:) = mlperts(i+1,:);
                end
            end
        end
        
        function usable = protocol_usable(self,mlperts)
            % we know the perturbation times from the protocol
            % but this is relative to the lag between the 'start' click on
            % the treadmill interface and on the vicon program. this functions checks if 
            % this lag is small and uniform, in which case it returns true -- the protocol is usable,
            % otherwise, it returns false.
            usable = false;
            unusenote = 'using only bamper and markers data for perturbation identification.';
            % go by the actual number of identified ML perturbations
            if strcmp(self.condition,'stand')
                tstrange = length(mlperts)*2;
            else
                tstrange = length(mlperts);
            end
            prot = self.protocol(1:tstrange)*self.datarate;
            if strcmp(self.condition,'stand')
                % in this case ML are the second, fourth,...
                protml = prot(2:2:end);
            else
                % if the condition is 'walk', they are all ML
                protml = prot;
            end
            delays = protml - mlperts(:,1);
            if max(abs(delays)) >= self.datarate*3 % more than 3 seconds of delay indicates that something is wrong
                warning('inconsistency between protocol and identified bamper movements\n%s',unusenote);
                return;
            end
            if ~all(sign(delays) == sign(delays(1))) % also the det
                warning('inconsistent protocol/bamper lag.\n%s',unusenote);
                return;
            end
            % all the lags are smaller than 3 seconds and have the same sign.
            % negative: bamper was activated first, positive: vicon capture was activated first.
            % now check the likelihood for one matching the other + the average lag up to some normally distributed noise
            delay = mean(delays);
            [h,p] = ttest(delays - delay);
            if (h == 1) || (p <= 0.75) % see matlab's ttest documentation
                warning('the protocol points are too loosely aligned with the identified points.\n%s',unusenote);
                return;
            end
            usable = true;
        end

        function perttimes = adjustMLperts(self,perts)
            % move perturbation start times to half way between identified times and protocol times
            if strcmp(self.condition,'stand')
                protml = self.protocol(2:2:end);
            else
                protml = self.protocol;
            end
            protml = protml(1:length(perts))*self.datarate;
            perttimes(:,1) = perts(:,1) + round((protml - perts(:,1))/2);
            perttimes(:,2) = perts(:,2);
        end

        function self = read_protocol(self)
            self.protocol = [];
            [p,~,~] = fileparts(self.tarfile);
            protfiles = dir(fullfile(p,'*protocol*txt'));
            if ~isempty(protfiles)
                for i=1:length(protfiles)
                    f = protfiles(i).name;
                    if ~protfiles(i).isdir && ~isempty(regexpi(f,['.* ' self.condition '.*']))
                        pid = fopen(fullfile(p,f));
                        if ~regexp(fgetl(pid),'0[\d,]{6}$')
                            warning('protocol file seems to be not in format: %s',f);
                            return;
                        end
                        fclose(pid);
                        d = importdata(fullfile(p,f),',',1);
                        prot = sort(d.data(:,1));
                        self.protocol = prot(prot > 0);
                        break;
                    end
                end
            end
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
        
        function warnings = ValidateData(self,wrnpercent)
            % wrnpercent: when to warn of NaN in percentage of any numeric
            % sequence of "Vdata".
            d = self.fixed;
            f = fieldnames(d);
            warnings = {};
            for p=1:self.numperts
                withnans = [];
                for i = 1:length(f)
                    subj = d(p).(f{i});
                    [lb,mdim] = max(size(subj));    
                    if isa(subj,'double')
                        % maximal number of NaNs along the major dimension
                        % of the data
                        sn = max(sum(isnan(subj),mdim));
                        if sn > wrnpercent*lb/100
                            withnans = [withnans;[i,100*sn/lb]]; % mark the field, what percentage
                        end
                    end
                end
                if all(size(withnans) == 0)
                    continue;
                end
                nwithnans = sum(withnans(:,1) ~= 0);
                if nwithnans >= 1
                    fieldname = f{withnans(1,1)};
                end
                if nwithnans > 1
                    fieldname = [fieldname ' (and others...)'];
                end
                warnings{end +1} = sprintf('Perturbation %d: data for %s is at least %.2f%% NaN',p,fieldname,min(withnans(:,2)));
            end
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
            % for now, we'll assume all saved data is by the new version
            %if isempty(fieldnames(atts)) && ~isempty(fieldnames(d1)
            %    [r,cols,~] = self.dBlock('trajectories');
            %    atts.datarate = r;
            %    atts.trajcolumns = cols;
            %    atts.numperts = length(d1);
            %end

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
            self.datarate = double(drate{:});
            self.trajcolumns = bcolumns;

            function [lcols,rcols] = left_and_right(colbase,offstbmpr)
                % returns the column vector corresponding to the left and right [x y z ]
                % vectors of "base"
                left = self.cellindex(bcolumns,['L' colbase]);
                right = self.cellindex(bcolumns,['R' colbase]);
                lcols = traj(:,left:left+2);
                rcols = traj(:,right:right+2);
                % offset the x column against the bamper
                if offstbmpr
                    lcols(:,1) = lcols(:,1) - bamperDisplacement(:,1);
                    rcols(:,1) = rcols(:,1) - bamperDisplacement(:,1);
                end
            end

            
            % find [ x y  z ] coordinate of the left bumper-marker
            bamper = self.cellindex(bcolumns,'bamperL');  
            bamperDisplacement = traj(:,bamper:bamper+2) - traj(1,bamper:bamper+2);    
            
            
            % ankles,heels toes, arm
            [leftAnkle,rightAnkle]  = left_and_right('ANK',true);
            [leftHeel,rightHeel] = left_and_right('HEE',false);
            [leftToe,rightToe] = left_and_right('TOE',false);
            [leftArm,rightArm] = left_and_right('FIN',true);
            
            % Center of Mass
            
            %% discuss with Inbal, if model and traj lengths are different...
            % cut to shorter ?? god knows what errors will be thrown later
            % if the difference is not eliminated now
            lmodel = size(model,1);
            ltraj = size(traj,1);
            if lmodel ~= ltraj
                warning('model and markers tables are not the same length: %d vs. %d respectively.\n this about %.1f seconds. eliminating the excess in the longer one',lmodel,ltraj,abs(lmodel-ltraj)/self.datarate);
                r = 1:min(lmodel,ltraj);
                model = model(r,:);
                traj = traj(r,:);
                bamperDisplacement = bamperDisplacement(r,:);
            end
            model(:,3)  = model(:,3) - bamperDisplacement(:,1);
            
            perTimes = self.findMLpert(bamperDisplacement(:,1));   %lateral
            
            assert(~isempty(perTimes),'cann''t find ML perturbations. Aborting!');
            
            useprot = self.protocol_usable(perTimes);
            if useprot
                perTimes = self.adjustMLperts(perTimes);
            end

            if strcmp(self.condition,'stand')
                ank = abs(leftAnkle(:,2)) + abs(rightAnkle(:,2));
                perTimes = self.findAPpert(ank,perTimes,useprot); % anterior-posterior
            end
            
            self.numperts = length(perTimes);
            for pind=1:length(perTimes)
                register_pert(pind);
            end
            
            self.fixed = d1;
            self.mutables = d2;
  

            function register_pert(perturbation_index)
                p = perturbation_index;
                twosec = double(2*self.datarate);
                segment_start =  perTimes(p,1) - twosec;
                segment_end = perTimes(p,2) + 3*self.datarate; 
                trange = segment_start:segment_end;
                lAnkleX = leftAnkle(trange,1);
                rAnkleX = rightAnkle(trange,1);
                lHeelY = leftHeel(trange,2);
                lToeY = leftToe(trange,2);
                rHeelY = rightHeel(trange,2);
                rToeY= rightToe(trange,2);
                leftArmX = leftArm(:,1);
                rightArmX = rightArm(:,1);
                cgcol = self.cellindex(acolumns,'CentreOfMass');
                CG = model(trange,cgcol:cgcol+2);
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
                
                % ?? offset the first CG from leg markers ??
                lAnkleX = lAnkleX - CG(1,1);
                rAnkleX = rAnkleX - CG(1,1);
                lHeelY = lHeelY - CG(1,2);
                rToeY= rToeY - CG(1,2);
                rHeelY = rHeelY - CG(1,2);
                lToeY= lToeY - CG(1,2);
                CG = CG - CG(1,:);
               
                
                % find when CG is out of legs
                % the directions are reversed, so the upperbound is left for ML
                % and heels for AP
                if strcmp(self.perturbation_type(p),'ML')
                    cgOut = ViconData.isOutOf(lAnkleX,rAnkleX,CG(:,1));
                else % AP
                    cgOut = ViconData.isOutOf(max(lHeelY,rHeelY),min(lToeY,rToeY),CG(:,2));
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
                d1(p).pertubationsTime = perTimes(p,:);
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
                d1(p).SFdATA = traj(trange,:);
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
                    d2(p).(field{:}) = d1(p).(field{:});
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
                    [p,f,e] = fileparts(self.tarfile);
                    system(['powershell -file pws.ps1 -directory "' p '" -targetfile "' f e '"']);
                catch err
                    disp(err);
                    return;
                end
            end

            assert(exist(tar,'file') > 0,'could not find source for %s\nplease check: %s',part,self.tarfile);
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
            
            % temp solution for true holes in the data discuss with Inbal
            if any(isnan(dat))
                dat = fillmissing(dat,'spline');
            end
            %dat = dlmread(tar,',',linecount+1,0);
        end
        
        function t = perturbation_type(self,ind)
            t = 'ML';
            if strcmp(self.condition,'stand') && mod(ind,2) == 1
                t = 'AP';
            end
        end          
    end
end
