classdef GaitEvents
    % given a directory, this class provides some methods for
    % gait analysis of the data in it.
    properties (Constant)
        smoothwindow = 10; % trial and error shows this is reasonable
        scanwindow = 20; % this is just to make sure the scan method doesn't pick up on some single missread. could be set heigher maybe.
        slope_thresh = 0.1; % this does not depend on the data **assuming the diff is devided by the delta width i.e 1/datarate**
        cycles_filename = 'GaitCycleParameters.csv'; % assuming no one changed file names...
        forces_filename = '2 ForcePlateResults @0.5 kHz.csv'; % note that it will always say 0.5Hz regardless of the actual datrate of the export
    end
    properties
        datarate
        datafolder
        reversed
        forces
        deriv_peak_dist
        left_hs
        right_hs
    end
    methods (Static)
        function [rate,dat] = load_forces(folder)
            forcesfile = fullfile(folder,GaitEvents.forces_filename);
            if ~exist(forcesfile,'file')
                zips = dir([folder '\*.zip']);
                if size(zips,1) == 1
                    disp('unzipping the data...');
                    unzip(fullfile(folder,zips(1).name),folder);
                end
            end
            f = importdata(forcesfile);
            rate = 1/(f.data(2,1) - f.data(1,1)); % Hz
            dat = array2table(f.data,'VariableNames',{'time','fz','copx','copy'});
        end
        function ctable = load_cycles(folder)
            ctable = false;
            cycfile = fullfile(folder,GaitEvents.cycles_filename);
            if exist(cycfile,'file')
                cyc = importdata(cycfile);
                ctimes = cell2mat(cellfun(@str2num,cyc.textdata(:,1),'UniformOutput',false));
                cdat = array2table(cyc.data(:,2:5),'VariableNames',{'duration','stepL','stepR','width'});
                cdat.time = ctimes;
                ctable = cdat;            
            else
                warning('can''t find the cycles file, there will be no step length data');
                return;
            end
        end
        function hs = improve_on_cop(bycopx,rightend,fz)
            % improve hs identification with force data.
            % within the ith stretch, find maximal fz slope
            % then scan from cop identification forward up to the max slope index,
            % until the downslope point preceeding a
            % the longest positive slope is reached.
            start = bycopx - floor(GaitEvents.scanwindow/2);
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
                thresh = GaitEvents.slope_thresh;
            end
            cur = idxs(curind);
            sc = GaitEvents.scanwindow;
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
            ind = GaitEvents.scanbackward(dat,idxs,curind,thresh*1.2);
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
        function self = GaitEvents(folder)
            % constructor takes just one parameter -- the folder
            % wehre the treadmill data is expected. the file names are:
            % "0 NI_Daq_Inputs @0.5 kHz.csv" -- not used here
            % "1 _Inputs @0.05 kHz.csv" -- raw voltages, not used here
            % "2 ForcePlateResults @0.5 kHz.csv" -- columns: Time   Fz  COPx    COPy
            % GaitCycleParameters.csv -- columns: Time	Cycle	Excercise	Evaluate	Duration[s]	StepL[mm]	StepR[mm]	StepWidth[mm]	Speed[m/s] 
            % but importdata manages only from 3 to end, so step width is
            % in column 5 instead of 8
            % ClientData.csv -- irrelevant
            self.datafolder =  folder;
            [self.datarate,self.forces] = GaitEvents.load_forces(folder);
            c = importdata(fullfile(folder,GaitEvents.cycles_filename));
            self.reversed = length(find(c.data(:,5) < 0)) > length(find(c.data(:,5) > 0));
            self.deriv_peak_dist = self.datarate/1.5;  %assuming lhs -> lhs frequency is not more than 1Hz
        end

        function self = find_heel_strikes(self) 
            % finds heel strikes by copx slope
            % ends of plataeus are detected as heel strikes.
            % it will also plot it for visual inspection
            scopx = movmean(self.forces.copx,GaitEvents.smoothwindow);
            deriv = diff(scopx) * self.datarate;
            smoothed_deriv = movmean(deriv,GaitEvents.smoothwindow);
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
                    self.deriv_peak_dist,'MinPeakHeight',2*GaitEvents.slope_thresh);
                heel_strikes = nan*ones(length(idx),1);
                for i = 2:length(idx)
                    bycopx = GaitEvents.scanbackward(smoothed_deriv*slopesign,idx,i);
                    heel_strikes(i) = bycopx;
                    byfz = GaitEvents.improve_on_cop(bycopx,idx(i),self.forces.fz);
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
                heel_strikes = GaitEvents.squish(heel_strikes,self.deriv_peak_dist/2);
                % eliminate nan, that can arise due to failed
                % identification
                heel_strikes = heel_strikes(~isnan(heel_strikes));
                allhs.(side{:}) = [heel_strikes,scopx(heel_strikes)];
            end
            % show what was found
            figure;
            c = plot(scopx);
            hold on;
            dotts = cell(0,2);
            for side = 1:2
                sidename = 'left';
                if side == 2
                    sidename = 'right';
                    pstyle = 'g*';
                else
                    pstyle = 'r*';
                end
                hs = allhs.(sidename);
                for i = 1:length(hs)
                    dotts{i,side} = plot(hs(i),scopx(hs(i)),pstyle);
                end
            end
            lh(1) = c;
            lh(2) = dotts{:,1};
            lh(3) = dotts{:,2};
            self.add_fz([allhs.left;allhs.right]);
            legend(lh,{'copx','left hs','right hs'});
            hold off;
            self.left_hs = allhs.left;
            self.right_hs = allhs.right;
        end
        
        function add_fz(self,hss)
            fz = self.forces.fz;
            plot((movmean(fz,GaitEvents.smoothwindow/2)/mean(fz))*max(self.forces.copx + 0.05))
            ylm = get(gca,'Ylim');
            for i=1:length(hss)
                linex = hss(i);
                line([linex,linex],ylm,'color',[0.5,0.5,0.5]);
            end
        end
        
        function s = get_strikes(self,side)
            assert(any(strcmp({'right','left'},side)),'side must either right or left (string)');
            if isempty(self.right_hs) % doesn't matter if one is both are
                self = self.find_heel_strikes(); % in matlab changing "self" requires that it be a return value
            end
            s = self.([side '_hs']);
        end

        function sds = stride_durations(self,side)
            % duration of 'side' hs to subsequent 'side' hs
            strikes = self.get_strikes(side);
            sds = diff(strikes(:,1))/self.datarate;
        end

        function sds = step_diffs(self,side,col) 
            % scan the lhs/rhs vectors starting with 'side'
            % for subsequent heel strikes of the other leg
            % when found, register the difference according to 'col' -- 1 is the timing, 2 is the copx
            if strcmp(side,'left')
                opposide = 'right';
            else
                opposide = 'left';
            end
            strikes1 = self.get_strikes(side);
            strikes2 = self.get_strikes(opposide);
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
        end
        
        function sds = step_durations(self,side)
            % duration of 'side' hs to subsequent 'oposide' hs
            sds = self.step_diffs(side,1)/self.datarate;
        end

        function wds = step_widths(self,side)
            % step widths between 'side' hs and 'opposide' hs
            wds = abs(self.step_diffs(side,2));
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
            cycdata = GaitEvents.load_cycles(self.folder);
            gaitforce.cycles = cycdata.time;
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
                if any(fgdif > 1/self.datarate) || any(fgmaxdif > self.deriv_peak_dist/2/self.datarate)
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
    end
end
