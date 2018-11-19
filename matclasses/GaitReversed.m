classdef GaitReversed < GaitEvents
    %GAITREVERSED.m Helper class to read from GaitForce outputs
    % Inherits from GaitEvents. Meant to be used where the GaitForce output
    % is incomplete. Includes methods for identification of heel strikes and toe offs
    properties(Constant)
        smoothwindow = 10; % trial and error shows this is reasonable
        scanwindow = 20; % this is just to make sure the scan method doesn't pick up on some single missread. could be set heigher maybe.
        slope_thresh = 0.1; % this does not depend on the data **assuming the diff is devided by the delta width i.e 1/datarate**
        lcopformat = '%d\t%s\tCOP\t%f\t%f\t%f\n\r';
    end
    properties
        right_hs
        left_hs
        has_loaded_from_disk
        savefilename
        toe_offs
    end
    methods(Static)
        function [left,right,dels] = alternate(sourcel,sourcer)
            % stack concept: peek left (completely arbitrarily),
            % pop from right until greater, then from left...
            left  = -1;
            right = -1;
            leftdone = false;
            rightdone = false;
            numdels = 0;
            lastused = 2; % 1 -- left, 2 -- right
            while ~(leftdone || rightdone)
                % if last was right, pop from left until ok and assign
                if lastused == 2
                    if ~isempty(sourcel)
                        while sourcel(1) < right(end) && length(sourcel) > 1
                            numdels = numdels + 1;
                            sourcel = sourcel(2:end);                    
                        end
                        left = [left;sourcel(1)];
                        sourcel = sourcel(2:end);
                        lastused = 1;
                    else
                        leftdone = true;
                    end
                else
                    if ~isempty(sourcer)
                        while sourcer(1) < left(end) && length(sourcer) > 1
                            numdels = numdels + 1;
                            sourcer = sourcer(2:end);                    
                        end
                        right = [right;sourcer(1)];
                        sourcer = sourcer(2:end);
                        lastused = 2;
                    else
                        rightdone = true;
                    end                
                end
            end
            left = left(2:end);
            right = right(2:end);
            dels = numdels;
        end
        function hs = improve_on_cop(bycopx,rightend,fz)
            % improve hs identification with force data.
            % within the ith stretch, find maximal fz slope
            % then scan from cop identification forward up to the max slope index,
            % until the downslope point preceeding a
            % the longest positive slope is reached.
            start = bycopx - floor(GaitReversed.scanwindow/2);
            fz = fz(start:rightend);
            dfz = diff(fz);
            % rule of thumb, search from the point found by cop up to the
            % point where fz is steepest
            [maxslope,mi] = max(dfz);
            if mi == 1
                hs = 'maximal slope is at left end';
                return;
            end
            fz = fz(1:mi+1);
            % separations between down slopes are the lengths of the up slopes
            increase_lengths = diff(find(dfz(1:mi) < 0));
            if isempty(increase_lengths)
                origminlength = mi;
            else
                origminlength = max(increase_lengths);
            end
            function slopestart = longsteep(minslope,minlength)
                % returns the index preceeding a minlength-long sequence
                % in fz, where fz only rises and the overall steepness is
                % high. first the steepness is relaxed, then the length
                absminslope = 0.7*maxslope;
                slopestart = 1;
                if minlength == 1 && minslope <= absminslope
                    % scanning for the long slope was complete with no
                    % results. so find minimal fz
                    [~,minval_index] = min(fz);
                    dsv = length(fz) - minval_index;
                    
                    % if it's far from the right end, take the last point
                    % of really flat fz
                    if  dsv > length(fz)/2
                        slopestart = find(diff(fz) < 0.2*maxslope,1,'last');
                        % fz is never flat in this range -- take 2 before
                        % steepest
                        if isempty(slopestart)
                            slopestart = length(fz) - 2;
                        end
                    % if it's pretty close, take the low point 
                    else
                        slopestart = minval_index;
                    end
                    return;
                end
                % the scan itself
                while slopestart < length(fz) - minlength
                    stretch = fz(slopestart:slopestart+minlength);
                    if isempty(stretch)
                        return;
                    end
                    if all(diff(stretch) > 0) && (stretch(end) - stretch(1))/minlength >= minslope
                        return;
                    end
                    slopestart = slopestart + 1;
                end
                % scan came up empty, adjust the parameter and recurse
                if minslope > absminslope
                    minslope = minslope*0.95;
                elseif minslope <= absminslope
                    minslope = maxslope;
                    minlength = minlength - 1;
                end
                slopestart = longsteep(minslope,minlength);
            end
            long_increase_starts = longsteep(maxslope,origminlength);
            if start + long_increase_starts > bycopx
                hs = start + long_increase_starts;
            else
                hs = 'was of no use';
            end
        end
        function ind = scanbackward(dat,idxs,curind,thresh)
            if nargin == 3
                thresh = GaitReversed.slope_thresh;
            end
            cur = idxs(curind);
            sc = GaitReversed.scanwindow;
            leftlim = 1;
            if curind > 1
                leftlim = idxs(curind - 1);
            end
            while cur > leftlim
                avg = mean(dat(cur  - sc:cur));
                if avg < thresh
                    ind = cur;
                    return
                end
                cur = cur - sc;
            end
            % if not found, scan again with larger threshold
            % fprintf('not found between %d and %d\n',idxs(curind),leftlim);
            %ind = round((idxs(curind) - idxs(curind - 1))/2);
            ind = GaitReversed.scanbackward(dat,idxs,curind,thresh*1.2);
        end
        function ind = scanforward(d,from,to)
            cur = from;
            while abs(mean((d(cur:cur+GaitReversed.smoothwindow)))) > 0.05 && cur < to 
                cur = cur + round(GaitReversed.smoothwindow/2);
            end
            ind = cur;
        end
        function ind = improve_toeoff(from,to,fz)
            [~,i] = min(fz(from:to));
            ind = from + i;
        end
        function d = squish(data,window)
            inds = find(diff(data) < window);
            for i=1:length(inds)
                data(inds(i)+1) = floor(mean(data(inds(i):inds(i)+1)));
            end
            d = data(~ismember(1:length(data),inds)); 
        end
    end
    
    methods
        function self = GaitReversed(folder,subjpattern)
            self@GaitEvents(folder,subjpattern);
            self.stage_reject_message = 'mark the stages again? [y/n] ';
            svn = fullfile(self.datafolder,[self.subjid '_hsandboundaries.mat']);
            self.has_loaded_from_disk = false;
            if exist(svn,'file')
                fprintf('loading stage boundaries and heel strikes from:\n%s\n',svn);
                load(svn,'dat');
                self.left_hs = dat.left_hs;
                self.right_hs = dat.right_hs;
                self.stages = dat.stages;
                self.numstages = length(dat.stages);
                self.has_loaded_from_disk = true;
                clear dat;
            end
            self.savefilename = svn;
        end
        
        function self = load_salute_stages(self,pat)
            protfiles = syshelpers.subdirs(self.datafolder,pat,true);
            assert(~isempty(protfiles),'could not find the protocol file');
            self = self.read_protocol(protfiles{1,1}{:});
            iskat = isempty(regexpi(self.datafolder,'salute'));
            if ~isempty(regexpi(self.datafolder,'(pre|day1)','match'))
                stagenames = {'slow1','fast','slow2','adaptation','post_adaptation'};
                timings = [10,130,140,260,270,390,400,1000,1010,1310];
                if iskat
                    stagenames = {'slow','fast','adaptation','post_adaptation','re_adaptation'};
                    timings = [10,70,80,140,150,510,520,880,890,1130];
                end
            elseif ~isempty(regexpi(self.datafolder,'(post|day2)','match'))
                stagenames = {'fast','salute','post_salute'};
                timings = [10,310,940,970,1270];
                if iskat
                    stagenames = {'slow','fast','adaptation','post_adaptation','re_adaptation'};
                    timings = [10,70,80,140,150,510,520,880,890,1130];
                end
            else
                error('something''s wrong');
            end
            for s=1:length(stagenames)
                t = s;
                if mod(s,2) == 0
                    t = s+1;
                end
                stages(s) = struct('name',stagenames{s},'limits',[timings(t),timings(t+1)]);
            end
            self.stages = stages;
            self.numstages = length(stagenames);
        end
        
        function self = load_ps_stages(self)
            % reads the stages from the protocol and names them by the 
            % log file produced in the gazing points experiment if exists
            protfilename = [self.subjid '-protocol.txt'];
            self = self.read_protocol(protfilename);
            self.numstages = sum(diff(self.protocol.onset_time) > 20); % !CAUTION! this assumes the protocol standing periods are no longer than 20 seconds
            logfile = fullfile(self.datafolder,[self.subjid '-log.txt']);
            if ~exist(logfile,'file')
                warning('could not find the log file. conditions will be numerically named');
                for i = 1:self.numstages
                    stages(i) = struct('name',num2str(i),'limits',[]);
                    self.stages = stages;
                end
                return
            end
            pid = fopen(logfile);
            tline = fgetl(pid);
            % go to where the trial sequence is listed
            while ischar(tline)
                if regexp(tline,'.*test\s+conditions.*')
                    break;
                end
                tline = fgetl(pid);
            end
            % fill the stages struct array as long as there are appropriate
            % lines in the file
            rstage = 0;
            while ischar(tline)
                [toks,flag] = regexp(tline,'(^\d+\.)([\w\s]+)(\(.+\)$)','tokens');
                if flag
                    rstage = rstage +1;
                    stages(rstage) = struct('name',strip(toks{:}{2}),'limits',[]);
                end
                tline = fgetl(pid);
            end
            fclose(pid);
            self.stages = stages;
            if length(self.stages) ~= self.numstages
                warning('the number of stages in the protocol doesnt match the one in the log file');
            end
        end
        function self = group_events(self,ev)
            if isempty(self.stages) || isempty([self.stages(:).limits])
                warning('must resolve stage limits first');
                return;
            end
            if strcmp(ev,'TO')
                if isempty(self.left_hs)
                    warning('must perform initial toe off identification first');
                    return;
                end
            elseif strcmp(ev,'HS')
                if isempty(self.left_hs)
                    warning('must perform initial heel strike identification first');
                    return;
                end
            end
            for s=1:self.numstages
                [lfirst,llast,rfirst,rlast] = self.edge_events(s,ev);
                fprintf('aligning stage no. %d -- %s: ',s,self.stages(s).name);
                if strcmp(ev,'HS')
                    left = self.left_hs(lfirst:llast,1);
                    right = self.right_hs(rfirst:rlast,1);
                elseif strcmp(ev,'TO')
                    left = self.toe_offs.left(lfirst:llast,1);
                    right = self.toe_offs.right(rfirst:rlast,1);
                end
                [l,r,d] = GaitReversed.alternate(left,right);
                if strcmp(ev,'HS')
                    self.stages(s).left_hs = [l,self.forces.copx(l)];
                    self.stages(s).right_hs = [r,self.forces.copx(r)];
                elseif strcmp(ev,'TO')
                    self.stages(s).left_to = [l,self.forces.copx(l)];
                    self.stages(s).right_to = [r,self.forces.copx(r)];
                end
                fprintf('performed %d deletions (%.2f%%)\n',d,d*100/mean(numel(left),numel(right)));
                %self.show_heel_strikes(self.stages(s).left_hs,self.stages(s).right_hs);
                %hold off;
            end
        end
        function [lf,ll,rf,rl] = edge_events(self,stageindex,ev)
            limits = round(self.stages(stageindex).limits);
            for side = {'left','right'}
                if strcmp(ev,'TO')
                    events = self.toe_offs.(side{:});
                elseif strcmp(ev,'HS') 
                    events = self.get_strikes(side{:},-1);
                end
                first = find(events(:,1) > limits(1),1);
                last = find(events(:,1) > limits(2),1) - 1;
                if isempty(last)
                    last = length(events(:,1));
                end
                if startsWith(side{:},'l')
                    ll = last;
                    lf = first;
                else
                    rl = last;
                    rf = first;
                end
            end
        end
        
        function self = find_toe_offs(self)
            % given a  heel strike, scan forward until the copx
            % flattens to find the toe off for that side
            % assumes heel strikes have been grouped with
            % group_heel_strikes
            scopx = movmean(self.forces.copx,GaitReversed.smoothwindow);
            scopy = movmean(self.forces.copy,GaitReversed.smoothwindow);
            deriv = diff(scopx) * self.datarate;
            smoothed_deriv = movmean(deriv,GaitReversed.smoothwindow);
            smoothed_fz = movmean(self.forces.fz,GaitReversed.smoothwindow);
            fzderiv = diff(self.forces.fz);
            qstep = round(self.datarate/4); % i.e 0.25 seconds, the fz peaks are assumed farther than this. also the next - current gap should be smaller
            for s=1:length(self.stages)
                stage = self.stages(s);
                for side={'left','right'}
                    this_hs = stage.([side{:} '_hs']);
                    tofs = [];
                    if strcmp(side,'left')
                        oposide = 'right';
                    else
                        oposide = 'left';
                    end
                    op_hs = stage.([oposide '_hs']);
                    op_index = find(op_hs > this_hs(1,1),1);
                    % loop the left/right heel strikes
                    for i = 1:size(this_hs,1)
                        % constrict the search range to between the 
                        % current heel strike and the subsequent one (other
                        % foot)
                        strike = this_hs(i,1);
                        if op_index > length(op_hs)
                            continue;
                        else
                            nextstrike = op_hs(op_index);
                        end
                        search_range = strike:nextstrike;
                        % the GaitForce method seems to be the max upward slope
                        % of fz between the two relevant peaks -- the first is
                        % right after the heel strike.
                        % the second is ??
                        if nextstrike - strike < qstep
                            continue;
                        end
                        [fzpeaks,fpinds] = findpeaks(smoothed_fz(search_range),'MinPeakDistance',qstep);
                        if size(fzpeaks,1) >= 2
                            fzrange = strike + fpinds(1): strike + fpinds(2);
                        elseif size(fzpeaks,1) == 1
                            %fzrange = strike + fpinds(1):nextstrike;
                            [~,fzmin] = min(smoothed_fz(strike:nextstrike));
                            fzrange = (strike + fzmin):(strike + min(max(fpinds(1),fzmin),nextstrike));
                        else
                            fzrange = search_range;
                        end
                        [~,mslind] = max(movmean(fzderiv(fzrange),round(GaitReversed.smoothwindow/2)));
                        [~,maxcopy] = max(scopy(strike:nextstrike));
                        %tofs = [tofs;fzrange(1) + mslind];
                        tofs = [tofs;strike + maxcopy];
                        op_index = op_index + 1;
                        %byfz = GaitReversed.improve_toeoff(strike,nextstrike,self.forces.fz);
                        %tofs(i) = round(mean([bycopx,byfz]));
                        %tofs(i) = bycopx;
                    end
                    self.stages(s).([oposide '_to']) = tofs;
                end
            end
        end
        function self = find_heel_strikes(self) 
            % finds heel strikes by copx slope
            % ends of plataeus are detected as heel strikes.
            % it will also plot it for visual inspection
            scopx = movmean(self.forces.copx,GaitReversed.smoothwindow);
            deriv = diff(scopx) * self.datarate;
            smoothed_deriv = movmean(deriv,GaitReversed.smoothwindow);
            deriv_peak_dist = self.datarate/1.5;  %assuming lhs -> lhs frequency is not more than 1Hz
            % minima of the copx derivative mean that weight was moving
            % sharply from right to left so the points where this negative weight shift started
            % correspond to left heel strikes. for right ones -- the
            % oppsite.
            allhs = struct;
            for side = {'left','right'} 
                slopesign = 1;
                if strcmp(side{:},'left')
                    slopesign = -1;
                end
                
                % if the treadmill was run in revese, the left foot down
                % will be the copx positive peaks
                if self.reversed
                    slopesign = -1*slopesign;
                end
                [~,idx] = findpeaks(smoothed_deriv*slopesign,'MinPeakDistance',...
                    deriv_peak_dist,'MinPeakHeight',2*GaitReversed.slope_thresh);
                heel_strikes = nan*ones(length(idx),1);
                for i = 2:length(idx)
                    bycopx = GaitReversed.scanbackward(smoothed_deriv*slopesign,idx,i);
                    heel_strikes(i) = bycopx;
                    byfz = GaitReversed.improve_on_cop(bycopx,idx(i),self.forces.fz);
                    if isnumeric(byfz) && byfz > bycopx && byfz < idx(i)
                        %disp('prefer fz');
                        heel_strikes(i) = byfz;
                    end
                   % elseif isnumeric(byfz)
                   %     fprintf('range limits: [%d,%d] forces result: %d\n',bycopx,idx(i),byfz);
                   % else
                   %     disp(byfz);
                   % end
                end
                % unite really close points that can arise due to the
                % scanbackward recursion
                heel_strikes = GaitReversed.squish(heel_strikes,deriv_peak_dist/2);
                % eliminate nan, that can arise due to failed
                % identification
                heel_strikes = heel_strikes(~isnan(heel_strikes));
                allhs.(side{:}) = [heel_strikes,scopx(heel_strikes)];
            end
            self.left_hs = allhs.left;
            self.right_hs = allhs.right;
            self.show_heel_strikes(allhs.left,allhs.right,'hs',scopx);
            self.add_fz();
        end
        function show_grouped(self,ev)
            % plots the stage-grouped events "ev" on the copx line
            assert(strcmp(ev,'hs') || strcmp(ev,'to'),'event must be either ''to'' or ''hs''');
            l = [];
            r = [];
            for s = 1:self.numstages
                levs = self.stages(s).(['left_' ev]);
                revs = self.stages(s).(['right_' ev]);
                l = [l;levs(:,1)];
                r = [r;revs(:,1)];
            end
            self.show_heel_strikes(l(:,1),r(:,1),ev);
        end
        
        function show_heel_strikes(self,lhs,rhs,event_name,cop)
            figure;
            eu = upper(event_name);
            if nargin == 4
                cop = movmean(self.forces.copx,GaitReversed.smoothwindow);
            end
            c = plot(cop);
            hold on;
            dotts = cell(0,2);
            for side = 1:2
                hs = lhs;
                pstyle = 'r*';
                if side == 2
                    pstyle = 'g*';
                    hs = rhs;  
                end
                for i = 1:length(hs)
                    dotts{i,side} = plot(hs(i),cop(hs(i)),pstyle);
                end
            end
            lh(1) = c;
            lh(2) = dotts{:,1};
            lh(3) = dotts{:,2};
            legend(lh,{'COPX',['Left ' eu],['Right ' eu]});
        end
        
        function add_fz(self)
            fz = self.forces.fz;
            hss = [self.left_hs(:,1);self.right_hs(:,1)];
            plot((movmean(fz,GaitReversed.smoothwindow/2)/mean(fz))*max(self.forces.copx + 0.05),'HandleVisibility','off');
            ylm = get(gca,'Ylim');
            for i=1:length(hss)
                linex = hss(i);
                line([linex,linex],ylm,'color',[0.5,0.5,0.5],'HandleVisibility','off');
            end
            hold off;
        end
        
        function s = get_strikes(self,side,si)
            assert(any(strcmp({'right','left'},side)),'side must either right or left (string)');
            if isempty(self.right_hs) % doesn't matter if one is both are
                self = self.find_heel_strikes(); % in matlab changing "self" requires that it be a return value
            end
            if si > 0
                if isempty([self.stages(:).limits])
                    self = self.group_events('HS');
                end
                s = self.stages(si).([side '_hs']);
            else
                s = self.([side '_hs']);
            end
        end

        function sds = stride_durations(self,side,stage)
            % duration of 'side' hs to subsequent 'side' hs
            % if stage is provided, will return sorted out durations for
            % that stage
            if nargin == 2
                stageindex = -1;
            else
                stageindex = self.resolve_stage(stage);
            end
            strikes = self.get_strikes(side,stageindex);
            sds = diff(strikes(:,1))/self.datarate;
        end
        
        function ind = resolve_stage(self,s)
            if ischar(s)
                ind = find(strcmp({self.stages(:).name},s));
            elseif isinteger(s) && 1 <= s < self.numstages
                ind = s;
            else
                warning('incorrect stage provided. using global heel_strikes');
                ind = -1;
            end
        end
        
        function sds = step_diffs(self,side,col,stage) 
            % if global scan the lhs/rhs vectors starting with 'side'
            % for subsequent heel strikes of the other leg
            % if stage is provided, no need for scan, just take the stage
            % strikes of 'side'
            % when found, register the difference according to 'col' -- 1 is the timing, 2 is the copx
            if strcmp(side,'left')
                opposide = 'right';
            else
                opposide = 'left';
            end
            if nargin == 4
                stageindex = self.resolve_stage(stage);
            else
                stageindex = -1;
            end
            strikes1 = self.get_strikes(side,stageindex);
            strikes2 = self.get_strikes(opposide,stageindex);
            if nargin == 3
                cur2 = 1;
                sds = nan*ones(length(strikes1),1);
                for i=1:length(strikes1)
                    while cur2 <= length(strikes2) && strikes2(cur2,1) <= strikes1(i,1)
                        cur2 = cur2 + 1;
                    end
                    if cur2 <= length(strikes2)
                        sds(i) = strikes2(cur2,col) - strikes1(i,col);
                    end
                end
            else
                start2 = 1;
                while strikes2(start2,1) <= strikes1(1,1)
                    start2 = start2 + 1;
                end
                sds = strikes2(start2:end,col) - strikes1(1:length(strikes2)-start2+1,col);
            end
        end
        
        function sds = step_durations(self,side,stage)
            % duration of 'side' hs to subsequent 'oposide' hs
            sds = self.step_diffs(side,1,stage)/self.datarate;
        end

        function wds = step_widths(self,side,stage)
            % step widths between 'side' hs and 'opposide' hs
            wds = abs(self.step_diffs(side,2,stage));
        end
        
        function check_against_gaitforce(self)
            % read left heel strikes times from "List of COP points.txt"
            gaitforce = struct('list',[],'numlist',0,'cycles',[],'numcycles',0);
            rawcopx = self.forces(:,3);
            points = LoCopp(self.datafolder);
            if points.hasdata
                gaitforce.list = points.get_event('HSL',{'time'});
                gaitforce.numlist = points.length;
            end
            
            % read the same from "GaitCycleParameters"
            gaitforce.cycles = self.cycles.time;
            gaitforce.numcycles = length(gitforce.cycles);

            
            if ~(gaitforce.numlist || gaitforce.numcycles)
                return;
            end
            % compare between gaitforce and itself and print stuff to
            % console if needed
            if gaitforce.numcycles && gaitforce.numlist
                if length(gaitforce.cycles) ~= length(gaitforce.list)
                    disp('Force Gait left heel strikes are not the same number');
                    fprintf('cycles file: %d, list of cop points: %d\n',gaitforce.numcycles,gaitforce.numlist);
                    l = min(gaitforce.numcycles,gaitforce.numlist);
                    gaitforce.list = gaitforce.list(1:l);
                    gaitforce.cycles = gaitforce.cycles(1:l);
                end
                fgdif = abs(gaitforce.list - gaitforce.cycles);
                fgmdif = mean(fgdif);
                fgmaxdif = max(fgdif);
                if any(fgdif > 1/self.datarate) || any(fgmaxdif > deriv_peak_dist/2/self.datarate)
                    fprintf('Force Gait left heel strikes dont agree.');
                    fprintf('Mean difference: %fs (%.3f readings), max difference: %.3f\n',...
                        fgmdif,fgmdif*self.datarate,fgmaxdif);
                end
            end
            
            % use the list of cop points as reference if exists
            if gaitforce.numcycles && ~gaitforce.numlist
                ref = gaitforce.cycles;
            else
                ref = gaitforce.list;
            end    
            
            figure;
                c = plot(rawcopx);
                hold on;
                ours = self.left_hs(:,1);
                ourd = {};
                for i = 1:length(ours)
                    ourd{i} = plot(ours(i),rawcopx(ours(i)),'r*');
                end
                % force gait left heel strikes in readings
                fglhs = round((ref - self.forces(1,1))*self.datarate);
                theird = {};
                for i = 1:length(fglhs)
                    theird{i} = plot(fglhs(i),rawcopx(fglhs(i)),'g*');
                end
                lh(1) = c;
                lh(2) = ourd{:};
                lh(3) = theird{:};
                self.add_fz([fglhs;ours]);
                legend(lh,{'copx','our lhs','gaitforce lhs'});
                hold off;
            % some very basic statistics
            l = min(length(ours),length(fglhs));
            ours = ours(1:l,1);
            theirs = fglhs(1:l);
            discrep = ours - theirs;
            fprintf('maximal difference: %d\nmean difference: %d\nstd: %.4f\n',...
                max(abs(discrep)),mean(discrep),std(discrep));
        end
        function quick_export(self)
           % just dump all L/R steptimes,durations and widths to one csv
           % file
           longest = 0;
           exp = struct;
           for f={'stride_durations','step_durations','step_widths'}
               for side = {'left','right'}
                   eval(['col = self.' f{:} '(''' side{:} ''');']);
                   if size(col,1) > longest
                       longest = size(col,1);
                   end
                   exp.([f{:} '_' side{:}]) = col;
               end
           end
           exp.left_heel_strikes = self.left_hs(:,1)/self.datarate;
           exp.right_heel_strikes = self.right_hs(:,1)/self.datarate;
           fnms = fieldnames(exp);
           t = nan*ones(longest,length(fnms));
           for f = 1:size(t,2)
               datacolumn = exp.(fnms{f});
               t(1:size(datacolumn,1),f) = datacolumn;
           end
           writeme = array2table(t,'VariableNames',fnms);
           summary(writeme);
           [s,p] = uiputfile(fullfile(self.datafolder,'*.csv'));
           if s ~= 0
               writetable(writeme,fullfile(p,s),'Delimiter',',');
           end
        end
        
        function proper_export(self)
            % writes steptimes,durations, widths and DFA results to file
            % and plots DFA graphs along the way, for each stage separately
            % will output an excell with sheets corresponding to the stages
            warning('off','MATLAB:xlswrite:AddSheet');
            [s,p] = uiputfile(fullfile(self.datafolder,[self.subjid '-data-by-condition.xlsx']));
            if s == 0
                return;
            end
            fnms = {'stride_durations','step_durations','step_widths'};
            saveto = fullfile(p,s);
            A = double('A');
            for s=self.stages
                fprintf('entering stage: %s\n',s.name);
                % collect the data
                colnames = {};
                dcolnames = {};
                c = 0;
                dfas = [];
                longest = 0;
                for f=fnms
                    lr = struct;
                    for side = {'left','right'}
                        colname = [f{:} '_' side{:}];
                        colnames = [colnames,colname];
                        col = self.(f{:})(side{:},s.name);
                        lr.(side{:}) = col;
                        % write the data column
                        xlswrite(saveto,col,s.name,[char(A+c) '2']);
                        
                        if length(col) > longest
                            longest = length(col);
                        end
                        c = c + 1;
                    end
                    % add mean(left,right), cv(mean), mediancv(mean)
                    % columns
                    colnames = [colnames,['mean_' f{:}],[f{:} '_cv'],[f{:} '_medcv']];
                    minl = min(length(lr.left),length(lr.right));
                    col = mean([lr.left(1:minl),lr.right(1:minl)],2);
                    cv = GaitEvents.cv(col);
                    mcv = GaitEvents.medcv(col);
                    for dat = {col,cv,mcv}
                        xlswrite(saveto,dat{:},s.name,[char(A+c) '2']);
                        c = c+1;
                    end
                    % compute and register the DFA of the complete right
                    % left right left .. series
                    combined = nan*ones(1,numel(lr.left) +numel(lr.right));
                    if lr.left(1) < lr.right(1)
                        first = 'left';
                        second = 'right';
                    else
                        first = 'right';
                        second = 'left';
                    end
                    combined(1:2:2*length(lr.(first))) = lr.(first);
                    combined(2:2:1+2*length(lr.(second))) = lr.(second);
                    fprintf('computing DFA for %s\n',f{:}); 
                    [alph,rsq] = dfa(combined,true,[strrep(s.name,'_',' ') ' ' strrep(f{:},'_',' ')]);
                    %[alph,rsq] = dfa(combined);
                    dfas = [dfas,alph,rsq];
                    dcolnames = [dcolnames,[f{:} ' alpha'],[f{:} ' R^2']];
                end
                % add the header row
                xlswrite(saveto,colnames,s.name);
                % add alphas header 3 rows below the end of the longest
                % data columns
                xlswrite(saveto,{'DFA'},s.name,['A' num2str(longest+4)]);
                xlswrite(saveto,dcolnames,s.name,['A' num2str(longest+5)]);
                % add the alphas row 
                xlswrite(saveto,dfas,s.name,['A' num2str(longest+6)]);
            end
            syshelpers.remove_default_sheets(saveto);
        end
        function save_basic_data(self)
            dat = struct('left_hs',self.left_hs,'right_hs',self.right_hs,'stages',self.stages); %#ok<NASGU>
            save(self.savefilename,'dat');
        end
        function list_cop_points(self)
            destfile = fullfile(self.datafolder,'List of COP points.txt');
            fid = fopen(destfile,'wt');
            copx = self.forces.copx;
            copy = self.forces.copy;
            rowid = 1;
            function printline(eventname,copxval,copyval,eventtime)
                fprintf(fid,GaitReversed.lcopformat,rowid,eventname,copxval,copyval,eventtime);
                rowid = rowid + 1;
            end
            for i = 1:length(self.left_hs)
                hsl = self.left_hs(i);
                tol = self.toe_offs.left(i);
                printline('HSL',copx(hsl),copy(hsl),hsl/self.datarate);
                %fprintf(fid,GaitReversed.lcopformat,i+1,'MidSS',0.0,0.0,0.0);
                printline('TO',copx(tol),copy(tol),tol/self.datarate);
                if(i < length(self.right_hs))
                    hsr = self.right_hs(i+1);
                    tor = self.toe_offs.right(i+1);
                    printline('HSR',copx(hsr),copy(hsr),hsr/self.datarate);
                    printline('TO',copx(tor),copy(tor),tor/self.datarate);
                end
            end
            fclose(fid);
        end
    end
end
