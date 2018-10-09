classdef GaitForceEvents < GaitEvents
    %GAITFORCEVENTS.m Helper class to read from GaitForce outputs
    % Inherits from GaitEvents. Meant to be used where the GaitForce output
    % is complete, and the analysis is concerned with symmetries e.g the
    % Salute expriment
    properties
        basicnames
        prepost     
        basics
        points
        learning_data
        stages_offset
        part
    end

    methods
        function self = GaitForceEvents(folder,stagenames,basicnames,subjectpattern)
            %GAITFORCE construcor
            % folder: absolute path to the folder in which the GaitForce
            % exports and the protocol file are saved. zipped exports are
            % also ok.
            % stagenames: cell array of names for different stages in one
            % recording.
            % bascinames: cell array of names for the basic measurements to
            % extract from the GaitForce data e.g step length.
            % subject pattern: regex to match against the folder string, so
            % as to obtain the subject id for the instance. see wrapper
            % scripts for examples.
            self@GaitEvents(folder,subjectpattern);
            self.basicnames=  basicnames;
            ispre = ~isempty(regexpi(folder,'pre'));
            ispost = ~isempty(regexpi(folder,'post'));
            if ~ispre && ~ispost
                %error('The data folder must be a decendant of either a pre or a post folder');
                self.prepost = '';
            elseif ispre && ispost
                error('The data folder cannot be a decendant of both pre and post folders');
            end
            if ispre
                self.prepost = 'pre';
                snames = stagenames.pre;
                if ~isempty(regexp(self.subjid,'(13|10)','match'))
                    snames = stagenames.pre10;
                end
            elseif ispost 
                self.prepost = 'post';        
                snames = stagenames.post;
                if ~isempty(regexp(self.subjid,'(13|10)','match'))
                    snames = stagenames.post10;
                end
                if ~isempty(regexp(self.subjid,'(11|17|23)','match'))
                    part = regexp(self.datafolder,'part(1|2)','match');
                    if(isempty(strfind(self.subjid,'23')))
                        snames = stagenames.(['post11_' part{:}]);
                    else
                        snames = stagenames.(['post23_' part{:}]);
                    end
                end                    
            end
            numstages = length(snames);
            for i = 1:numstages
                stages(i) = struct('name',snames{i},'limits',[]); %#ok<AGROW>
            end
            self.stages = stages;
            self.numstages = numstages;
            self.points =  LoCopp(self.datafolder);
            self.stage_reject_message = 'automatic stage identification rejected. press any key but y to quit here: ';
        end
        
        function self = load_stages(self,pat)
            %LOADSTAGES read stage times from protocol file
            % pat: regexp pattern of protocol file name
            protfiles = syshelpers.subdirs(self.datafolder,pat,true);
            assert(~isempty(protfiles),'could not find the protocol file');
            self = self.read_protocol(protfiles{1,1}{:});
            times = self.protocol.onset_time;
            %assert(length(times) == self.numstages * 2 + 1,...
            %        'missmatch between protocol and given number of stages'...
            %);
            initial_offset = times(2);
            assert(times(1) == 0 && initial_offset > 0,'the protocol files does not include standing at the begining');
            curstage = 1;
            soffset = self.points.start - initial_offset;
            for r = 2:length(times)
                % skipping the 1st 10 seconds of standing               
                if self.protocol.speedL(r) == 0 &&  self.protocol.speedR(r) == 0
                    lseconds = times(r-1:r) + soffset;
                    % since usually I use readings
                    self.stages(curstage).limits = round((lseconds - self.forces.time(1))*self.datarate);
                    % since GaitForce only uses time
                    self.stages(curstage).times = lseconds;
                    curstage = curstage + 1;
                end
            end
            self.stages_offset= soffset;
        end
    
        function self = compute_basics(self)
            % create table for each stage
            for s = 1:self.numstages
                stage = self.stages(s);
                % eventually, you want a table which is easy to write to excell
                % but column lengths are not known at this point, so I just collect them to
                % a temp struct, from which i'll make the table at the end.
                tmp = struct;
                takecycles = self.cycles.time >= stage.times(1) & self.cycles.time < stage.times(2);
                % add the left and right columns of every base to the temp struct
                longest = 1;
                for base = self.basicnames
                    for side = {'left','right'}
                        varname = [base{:} '_' side{:}];                       
                        if strcmp(side{:},'left')
                            thiskey = 'HSL';
                            thatkey = 'HSR';
                        else
                            thiskey = 'HSR';
                            thatkey = 'HSL';
                        end
                        switch base{:}
                            case 'step_length'
                                % the steps lengths are given in the cycles
                                % file
                                cycles_key = ['step' upper(side{:}(1))];
                                datcol = self.cycles(takecycles,cycles_key).Variables;
                            case 'step_duration'
                                thistimes = self.points.get_event(thiskey,'time',stage.times).Variables;
                                thattimes = self.points.get_event(thatkey,'time',stage.times).Variables;
                                % now we have to sequences of HS timings, where 'this' is those of the current side
                                % the durations for left steps are diffs between left heel strikes and their preceding right ones
                                % find the first pair of 'this' and preceding 'that':
                                cur = 1;
                                while thistimes(cur) < thattimes(1)
                                    cur = cur + 1;
                                end
                                % now subtract by matching ranges
                                datcol = thistimes(cur:end) - thattimes(1:length(thistimes) - cur +1);
                            case 'stride_duration'
                                % since the cycles file only has the left stride timings,
                                % we might as well read both from the list of cop points
                                datcol = diff(self.points.get_event(thiskey,'time',stage.times).time);
                            case 'stride_length'
                                % i will naively assume that the left stride lengths are steplength_left + steplength_right in the same row
                                % of the cycles file, and that the right lenghts are steplength_right of row i + steplength_left of row i+1
                                lcols = self.cycles(takecycles,{'stepL','stepR'});
                                l = height(lcols);
                                if strcmp(side{:},'left')
                                    datcol = sum(lcols.Variables,2);                       
                                else
                                    datcol = lcols.stepR(1:l-1) + lcols.stepL(2:end);
                                end
                            case 'step_width'
                                % again the cycles files provides only left data
                                thiscopx = self.points.get_event(thiskey,{'time','copx'},stage.times);
                                thatcopx = self.points.get_event(thatkey,{'time','copx'},stage.times);
                                % here, it's this minus subsequent that, so find the minimal by time. 
                                cur = 1;
                                while thiscopx.time(1) > thatcopx.time(cur)
                                    cur = cur + 1;
                                end
                                minlength = min(height(thiscopx),height(thatcopx));
                                datcol = abs(thiscopx.copx(1:minlength - cur +1) - thatcopx.copx(cur:minlength));
                            case 'swing_duration'
                                hstimes = self.points.get_event(thiskey,'time',stage.times).Variables;
                                totimes = self.points.get_event(['TO' upper(side{:}(1))],'time',stage.times).Variables;
                                % find the first HS that's after the first TO
                                cur = 1;
                                while hstimes(cur) < totimes(1)
                                    cur = cur + 1;
                                end
                                datcol = hstimes(cur:end) - totimes(1:length(hstimes)-cur+1);
                                assert(all(datcol) > 0,'wrong swing');
                            case 'stance_duration'
                                hstimes = self.points.get_event(thiskey,'time',stage.times).Variables;
                                totimes = self.points.get_event(['TO' upper(side{:}(1))],'time',stage.times).Variables;
                                % find the first TO that's after the first HS
                                cur = 1;
                                while totimes(cur) < hstimes(1)
                                    cur = cur + 1;
                                end
                                datcol = abs(totimes(cur:end) - hstimes(1:length(totimes) - cur+1));
                            case 'ds_duration'
                                hstimes = self.points.get_event(thiskey,'time',stage.times).Variables;
                                if strcmp(side{:},'left')
                                    tokey = 'TOR';
                                else
                                    tokey = 'TOL';
                                end
                                totimes = self.points.get_event(tokey,'time',stage.times).Variables;
                                cur = 1;
                                while totimes(cur) < hstimes(1)
                                    cur = cur + 1;
                                end
                                datcol = totimes(cur:end) - hstimes(1:length(totimes) - cur + 1);
                        end
                        if length(datcol) > longest
                            longest = length(datcol);
                        end
                        tmp.(varname) = datcol;
                    end
                end
                % create the table from tmp and save it to self.basics
                fnames = fieldnames(tmp);
                stagedata = table();
                extras = struct;
                for n = 1:length(fnames)
                    name = fnames{n,1};
                    datcol = tmp.(name);
                    % initialize with some margin at the bottom for the cv
                    % and stuff
                    stagedata.(name) = [datcol;nan*ones(longest-length(datcol),1)];
                    % next to each pair, add it's symmetries series
                    if endsWith(name,'right')
                        bname = strrep(name,'_right',''); % this is a little stupid but...
                        leftname = [bname '_left'];
                        symsname = [bname '_symmetries'];
                        leftcol = tmp.(leftname);
                        %cv = GaitEvents.cv([leftcol;datcol]);
                        % these columns are coordinated by the construction
                        % of the self.basics tables, but the lengths don't
                        % always match. so just take by shortest
                        m = min(length(datcol),length(leftcol));
                        syms = VisHelpers.symmetries([leftcol(1:m),datcol(1:m)],true);
                        stagedata.(symsname) = [syms;nan*ones(longest-length(syms),1)];
                        extras.(bname).symcv = GaitEvents.cv(syms);
                        extras.(bname).meansym = nanmean(syms);
                        extras.(bname).symcv_first5 = GaitEvents.cv(syms(1:5));
                        extras.(bname).symcv_last5 = GaitEvents.cv(syms(end-5:end));
                        extras.(bname).meansym_first5 = nanmean(syms(1:5));
                        extras.(bname).meansym_last5 = nanmean(syms(end-5:end));
                    end
                end
                self.basics.(self.stages(s).name).data = stagedata;
                self.basics.(self.stages(s).name).extras = extras;
            end
        end
        function s = timespan(self,stage,bname,start,finish)
            % retruns the time elapsed between stage start and the split or
            % between the split and the end of the stage according to ba =
            % 1 / 2 respectively. TODO the time is computed by summing the
            % matching durations series in self.baics. A more solid
            % strategy would be to get it directly from self.points at
            % the data collection stage...
            
            bparts = split(bname,'_');
            if strcmp(bparts{2},'width')
                durbase = 'step_duration';
            else
                durbase = strrep(bname,'length','duration');
            end
            left = self.basics.(stage).data.([durbase '_left']);
            right = self.basics.(stage).data.([durbase '_right']);
            if any(strcmp(bparts{1},{'duration','stance'}))
                s = nansum(left(start:finish)); % arbitrarily could be more accurate...
            else
                s = nansum(left(start:finish)) + nansum(right(start:finish));
            end
        end
        function self = process_learning_times(self,times,b)
            %PROCESS_LEARNING_TIMES.m compute statistics for sub-stages of walking stages 
            % times: struct with stagename main attributes
            % the values represent the end of the learning phase relative to the 
            % start of the stage and the adjusted r2 of the curve fit i.e its goodness.
            % for example the value of times.adaptation would be the index
            % in which the learning was finished in the adaptation stage
            % symmetries series for the given basic measure.
            % b: the name of the basic measure e.g stride_duration
            lstages = fieldnames(times);
            for s = 1:length(lstages)
                stage = lstages{s};
                stageindex = find(strcmp(extractfield(self.stages,'name'),stage),1);
                assert(~isempty(stageindex),'something is wrong');
                %t = nan*ones(length(rows),length(self.basicnames));
                %t = array2table(t,'VariableNames',self.basicnames,'RowNames',rows);
                basictable = self.basics.(stage).data;
                splitindex = times.(stage).split;
                auto = 1;
                % under 5 points its meaningless
                if splitindex < 5
                    fprintf('couldn''t find the split in %s\n',stage);
                    splitindex = round(height(basictable)/2);
                    auto = 0;
                end               
                left = basictable.([b '_left']);
                right = basictable.([b '_right']);
                left1 = left(1:splitindex);
                left2 = left(splitindex+1:end);
                right1 = right(1:splitindex);
                right2 = right(splitindex+1:end);
                syms1 = VisHelpers.symmetries([left1,right1],true);
                syms2 = VisHelpers.symmetries([left2,right2],true);
                time1 = self.timespan(stage,b,1,splitindex);
                time2 = self.timespan(stage,b,splitindex+1,min(length(left),length(right)));
                % see self.export lcolumns below
                self.learning_data.(stage).(b) = [...
                    times.(stage).quality;...
                    auto;...
                    length(syms1);...
                    time1;...
                    GaitEvents.cv(syms1);...
                    self.basics.(stage).extras.(b).symcv_first5;...
                    nanmean(syms1);...
                    self.basics.(stage).extras.(b).meansym_first5;...
                    length(syms2);...
                    time2;...
                    GaitEvents.cv(syms2);...
                    self.basics.(stage).extras.(b).symcv_last5;...
                    nanmean(syms2);...
                    self.basics.(stage).extras.(b).meansym_first5;...
                    min(length(left)-sum(isnan(left)),length(right)-sum(isnan(right)));...
                    time1 + time2;...
                    self.basics.(stage).extras.(b).symcv;...
                    self.basics.(stage).extras.(b).meansym...
               ];
            end           
        end
        
        function self = combine(self,other)
            if isempty(self.basics) || isempty(other.basics)
                return;
            end
            thislastname = self.stages(self.numstages).name;
            otherfirstname = other.stages(1).name;
           
            % if the current object last stage is the same as the second
            % one's, merge this basic table and update the extras to the
            % mean of both objects
            if(strcmp(thislastname,otherfirstname))
                self.basics.(thislastname).data = [self.basics.(thislastname).data;other.basics.(thislastname).data];
                for bname=self.basicnames
                    b = bname{:};
                    e1 = self.basics.(thislastname).extras.(b);
                    %e2 = other.basics.(thislastname).extras.(b);
                    newsyms = self.basics.(thislastname).data.([b '_symmetries']);
                    e1.symcv = GaitEvents.cv(newsyms);
                    e1.meanysym = mean(newsyms);
                    e1.symcv_first5 = GaitEvents.cv(newsyms(1:5));
                    e1.symcv_last5 = GaitEvents.cv(newsyms(end-5:end));
                    e1.meansym_first5 = nanmean(newsyms(1:5));
                    e1.meansym_last5 = nanmean(newsyms(end-5:end));
                    self.basics.(thislastname).extras.(b) = e1;
                end
                restindex = 2;
            else
                restindex = 1;
            end
            % add the rest of the basic tables to basics
            othernames = fieldnames(other.basics);
            for f = restindex:length(othernames)
                n = othernames{f};
                self.basics.(n) = other.basics.(n);
                self.stages = [self.stages,struct('name',n,'limits',[],'times',[])];
                self.numstages  = self.numstages + 1;
            end
        end
        
        function export(self)
            A = int16('A');
            warning('off','MATLAB:xlswrite:AddSheet');
            putname = self.subjid;
            if ~isempty(self.prepost)
                putname = [putname,'-',self.prepost];
            end
            putname = [putname '.xlsx'];
            [s,p] = uiputfile(putname);
            lrows = {...
                'quality','detection by curve','steps1','time1','symcv1','symcv_first5',...
                'meansym1','meansym_first5','steps2','time2','symcv2','symcv_last5',...
                'meansym2','mansym_last5','stepstotal','timetotal','cvtotal','meantotal'...
            };
            if s ~= 0
                saveto = fullfile(p,s);
                if exist(saveto,'file')
                    delete(saveto);
                end
                for s=1:self.numstages
                    stagename = self.stages(s).name;
                    dsource = self.basics.(stagename);
                    h = height(dsource.data);
                    % write the basic series -- left,right,symmetries
                    writetable(dsource.data,saveto,'FileType',...
                        'spreadsheet','Sheet',stagename);
                    
                    % if the current stage was fitted a curve, write that
                    % to same sheet. in this case, there is no need for the
                    % extras row.
                    if any(strcmp(fieldnames(self.learning_data),stagename))
                        ld = self.learning_data.(stagename);
                        bnames = fieldnames(ld); % should be the same as self.basicnames
                        xlswrite(saveto,{'curve fit data'},stagename,['A' num2str(h+9)]);
                        % write the basicnames as a header row -- offset
                        % one to the right because of the row names
                        xlswrite(saveto,bnames',stagename,['B' num2str(h+10)]);
                        % write a column with the learning rows names --
                        % one below the header
                        xlswrite(saveto,lrows',stagename,['A' num2str(h+11)]);
                        % loop the basic names and write the column of computed
                        % values under each
                        for b = 1:length(bnames)
                            xlswrite(saveto,ld.(bnames{b}),stagename,[char(A + b) num2str(h+11)]);
                        end
                    else
                        % write the extra data: cv and mean symm of every
                        % column in the dsource.data table
                        extras_header = {};
                        enames = fieldnames(dsource.extras);
                        row1 = [];
                        row2 = [];
                        row3 = [];
                        for b=1:length(enames)
                            bn = enames{b};
                            cv = dsource.extras.(bn).symcv;
                            meansym = dsource.extras.(bn).meansym;
                            f5cv = dsource.extras.(bn).symcv_first5;
                            l5cv = dsource.extras.(bn).symcv_last5;
                            f5m = dsource.extras.(bn).meansym_first5;
                            l5m = dsource.extras.(bn).meansym_last5;
                            extras_header = [extras_header,[bn '_symcv'],[bn '_meansym']];
                            row1 = [row1,cv,meansym];
                            row2 = [row2,f5cv,f5m];
                            row3 = [row3,l5cv,l5m];
                        end
                        xlswrite(saveto,extras_header,stagename,['A' num2str(h+5)]);
                        xlswrite(saveto,row1,stagename,['A' num2str(h+6)]);
                        xlswrite(saveto,row2,stagename,['A' num2str(h+7)]);
                        xlswrite(saveto,row3,stagename,['A' num2str(h+8)]);
                    end
                end
                syshelpers.remove_default_sheets(saveto);
            end
        end
    end
end

