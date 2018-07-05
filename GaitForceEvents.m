classdef GaitForceEvents
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
        function ind = scanbackward(dat,idxs,curind,thresh)
            if nargin == 3
                thresh = GaitForceEvents.slope_thresh;
            end
            cur = idxs(curind);
            sc = GaitForceEvents.scanwindow;
            leftlim = 1;
            if curind > 1
                leftlim = idxs(curind - 1);
            end
            while cur > leftlim
                avg = mean(dat(cur  - sc:cur));
                if avg < thresh
                    ind = cur - floor(sc/2);
                    return
                end
                cur = cur - sc;
            end
            % if not found, scan again with larger threshold
            % fprintf('not found between %d and %d\n',idxs(curind),leftlim);
            %ind = round((idxs(curind) - idxs(curind - 1))/2);
            ind = GaitForceEvents.scanbackward(dat,idxs,curind,thresh*1.5);
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
        function self = GaitForceEvents(folder)
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
            f = importdata(fullfile(folder,GaitForceEvents.forces_filename));
            self.datarate = 1/(f.data(2,1) - f.data(1,1)); % Hz
            self.forces = f.data;
            c = importdata(fullfile(folder,GaitForceEvents.cycles_filename));
            self.reversed = length(find(c.data(:,5) < 0)) > length(find(c.data(:,5) > 0));
            self.deriv_peak_dist = self.datarate/1.5;  %assuming lhs -> lhs frequency is not more than 1Hz
        end

        function self = find_heel_strikes(self) 
            % finds heel strikes by copx slope
            % ends of plataeus are detected as heel strikes.
            % it will also plot it for visual inspection
            copx = self.forces(:,3);
            % if the treadmill was run in revese, just flip the copx
            if self.reversed
                copx = -1*copx;
            end
            scopx = movmean(copx,GaitForceEvents.smoothwindow);
            deriv = diff(scopx) * self.datarate;
            smoothed_deriv = movmean(deriv,GaitForceEvents.smoothwindow);
            % minima of the copx derivative mean that weight was moving
            % sharply from right so the points where this negative weight shift started
            % correspond to left heel strikes. for right ones -- the
            % oppsite.
            allhs = cell(1,2);
            for side = [-1,1] % left right 
                [~,idx] = findpeaks(smoothed_deriv*side,'MinPeakDistance',...
                    self.deriv_peak_dist,'MinPeakHeight',2*GaitForceEvents.slope_thresh);
                heel_strikes = nan*ones(length(idx),1);
                for i = 2:length(idx)
                    bycopx = GaitForceEvents.scanbackward(smoothed_deriv*side,idx,i);
                    heel_strikes(i) = bycopx;
                    % now try to correct it with fz data:
                    % within the ith stretch, find steepest fz, then scan
                    % back until a a point where fz decresses
                    start = bycopx - GaitForceEvents.scanwindow;
                    fz = self.forces(start:idx(i),2);
                    dfz = diff(fz);
                    [~,mi] = max(dfz);
                    if mi > 1
                        disp('trying to use fz');
                        better = find(dfz(1:mi) < 0,1,'last');
                        if better
                            if start + better > bycopx
                                disp('prefer fz');
                                heel_strikes(i) = start + better;
%                                 if better > length(fz)/2
%                                     disp('but moderating')
%                                     heel_strikes(i) = start + floor(better/2);
%                                 end
                            else
                                disp('was of no use');
                            end
                            
                        end
                    else
                        disp('max fz slope is not between...')
                    end
                end
                % unite really close points that can arise due to the
                % scanbackward recursion
                heel_strikes = GaitForceEvents.squish(heel_strikes,self.deriv_peak_dist/2);
                % eliminate nan, that can arise due to failed
                % identification
                heel_strikes = heel_strikes(~isnan(heel_strikes));
                allhs{1,ceil((side+2)/2)} = [heel_strikes,scopx(heel_strikes)]; % -1 --> 1, 1 --> 2
            end
            % show what was found 
            c = plot(scopx);
            hold on;
            dotts = cell(0,2);
            for side = 1:size(allhs,2)
                hs = allhs{1,side};               
                for i = 1:length(hs)
                    if side == 1
                        pstyle = 'r*';
                    else
                        pstyle = 'g*';
                    end
                    dotts{i,side} = plot(hs(i,1),hs(i,2),pstyle);
                end
            end
            lh(1) = c;
            lh(2) = dotts{:,1};
            lh(3) = dotts{:,2};
            legend(lh,{'copx','left hs','right hs'});
            hold off;
            self.left_hs = allhs{1,1};
            self.right_hs = allhs{1,2};
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
        
        function check_against_forcegait(self)
            % read left heel strikes times from "List of COP points.txt"
            pointsfile = dir([self.datafolder '/*COP*.txt']);
            if isempty(pointsfile)
                disp('Sorry, couldn''t find ForceGaits list of COP points');
                return
             end
            fgpoints = importdata(fullfile(pointsfile.folder,pointsfile.name));
            if all(strcmp(fgpoints.textdata(:,1),''))
                fgpoints.textdata = fgpoints.textdata(:,2:end);
            end
            fglhs = fgpoints.data(strcmp(fgpoints.textdata(:,2),'HSL'),3);
            
            % read the same from "GaitCycleParameters"
            cyc = importdata(fullfile(self.datafolder,GaitForceEvents.cycles_filename));
            fglhs2 = cell2mat(cellfun(@str2num,cyc.textdata(:,1),'UniformOutput',false));

            % compare between forcegait and itself
            if length(fglhs2) ~= length(fglhs)
                disp('Force Gait left heel strikes are not the same number');
                fprintf('cycles file: %d, list of cop points: %d\n',length(fglhs2),length(fglhs));
                l = min(length(fglhs),length(fglhs2));
                fglhs = fglhs(1:l);
                fglhs2 = fglhs2(1:l);
            end
            
            fgdif = abs(fglhs - fglhs2);
            fgmdif = mean(fgdif);
            fgmaxdif = max(fgdif);
            if any(fgdif > 1/self.datarate) || any(fgmaxdif > self.deriv_peak_dist/2/self.datarate)
                fprintf('Force Gait left heel strikes dont agree.');
                fprintf('Mean difference: %fs (%.3f readings), max difference: %.3f\n',...
                    fgmdif,fgmdif*self.datarate,fgmaxdif);
            end
            figure;
                c = plot(self.forces(:,3));
                hold on;
                ours = self.left_hs;
                ourd = {};
                for i = 1:length(ours)
                    ourd{i} = plot(ours(i,1),ours(i,2),'r*');
                end
                % assuming the cycles data might be wrong
                fglhs = round((fglhs2 - self.forces(1,1))*self.datarate); % from seconds to readings
                theird = {};
                for i = 1:length(fglhs)
                    theird{i} = plot(fglhs(i),self.forces(fglhs(i),3),'g*');
                end
                lh(1) = c;
                lh(2) = ourd{:};
                lh(3) = theird{:};
                legend(lh,{'copx','our lhs','gaitforce lhs'});
                hold off;
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
