classdef GaitForceEvents
    %GAITFORCE Helper class to read from GaitForce outputs    


    properties
        datafolder
        subjid
        stages
        numstages
        basicnames
        prepost
        datarate
        forces
        datastarts
        basics
        points
        cycles
    end

    methods
        function self = GaitForceEvents(folder,stagenames,basicnames,subjectpattern)
            %GAITFORCE construcor
            %   the path to the data will provide necessary information
            self.basicnames=  basicnames;
            self.datafolder = folder;
            subjmatch = regexp(folder,subjectpattern,'match');
            if isempty(subjmatch)
                self.subjid = 'IDUNMATCHED';
            else
                self.subjid = subjmatch{:};
            end
            ispre = ~isempty(regexpi(folder,'pre'));
            ispost = ~isempty(regexpi(folder,'post'));
            if ~ispre && ~ispost
                error('The data folder must be a decendant of either a pre or a post folder');
            elseif ispre && ispost
                error('The data folder cannot be a decendant of both pre and post folders');
            end
            if ispre
                self.prepost = 'pre';
                stagenames = stagenames.pre;
            else
                self.prepost = 'post';
                stagenames = stagenames.post;
            end
            numstages = length(stagenames);
            for i = 1:numstages
                stages(i) = struct('name',stagenames{i},'limits',[]); %#ok<AGROW>
            end
            self.stages = stages;
            self.numstages = numstages;
            [self.datarate,self.forces] = GaitEvents.load_forces(folder);
            self.datastarts = self.forces.time(1);
            self.points =  LoCopp(self.datafolder);
            self.cycles = GaitEvents.load_cycles(folder);

        end
        function stages_rejected(self,~,~,~)
            uiresume(gcbf);
            proceed = input('the automatic stages where rejected. proceed manually [y/n]? ','s');
            if strcmp(proceed,'y')
                self = self.mark_stages(); %#ok<NASGU>
            else
                error('aborting. sort stuff out and come back when you''re ready');
            end
        end
        function self = load_stages(self)
            %LOADSTAGES read stage times from protocol file
            protfiles = syshelpers.subdirs(self.datafolder,'.*(salute)?.*(pre|post).*(left|right)?.*txt$',true);
            assert(~isempty(protfiles),'could not find the protocol file');
            pid = fopen(fullfile(self.datafolder,protfiles{1,1}{:}));
            c = textscan(pid,'%f;%f;%f');
            times = c{:,1};
            speeds = c{:,2};
            assert(length(times) == self.numstages * 2 + 1,...
                'missmatch between protocol and given number of stages');
            fclose(pid);
            initial_offset = times(2);
            assert(times(1) == 0 && initial_offset > 0,'the protocol files does not include standing at the begining');
            curstage = 1;
            for r = 2:length(times)
                % skipping the 1st 10 seconds of standing
                
                if speeds(r) == 0
                    self.stages(curstage).limits = times(r-1:r) + self.points.start - initial_offset;
                    curstage = curstage + 1;
                end
            end
        end
        
        function confirm_stages(self)
            figure;
            title('Please confirm that the stage boundaries');
            plot(self.forces.fz);
            xlabel('minutes');
            [t,l] = VisHelpers.minutes(1:size(self.forces.Variables,1),self.datarate);
            xticks(t);
            xticklabels(l);
            hold on;
            for s=1:self.numstages
                limits = (self.stages(s).limits - self.datastarts) * self.datarate;
                for l=1:2
                    line([limits(l),limits(l)],get(gca,'YLim'),'color','black','LineWidth',2,'Linestyle', '--');
                end
            end
            uicontrol('String','Confirm','Callback','uiresume(gcbf)',...
                'Position',[10 10 50 30]);
            uicontrol('String','Reject','Callback',@self.stages_rejected,...
                'Position',[100,10,50,30]);
            uiwait(gcf);
            close;
        end
        
        function self = mark_stages(self)
            %MARKSTAGES let the user mark the begining and end of every
            %stage in the trial manually
            figure;
            % plot fz for clearest walking phase
            plot(self.forces.fz);
            [limits,~] = ginput(self.numstages * 2);
            limits = sort(limits);
            for s=1:self.numstages
                self.stages(s).limits = ([limits(s),limits(s+1)] + self.datastarts)/self.datarate; % gaitforce specifies times in seconds
            end
            self.confirm_stages();
        end

        function self = compute_basics(self)
            % create table for each stage
            for s = 1:self.numstages
                stage = self.stages(s);
                % eventually, you want a table which is easy to write to excell
                % but column lengths are not known at this point, so I just collect them to
                % a temp struct, from which i'll make the table at the end.
                tmp = struct;
                takecycles = self.cycles.time >= stage.limits(1) & self.cycles.time < stage.limits(2);
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
                                thistimes = self.points.get_event(thiskey,'time',stage.limits).Variables;
                                thattimes = self.points.get_event(thatkey,'time',stage.limits).Variables;
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
                                datcol = diff(self.points.get_event(thiskey,'time',stage.limits).time);
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
                                thiscopx = self.points.get_event(thiskey,{'time','copx'},stage.limits);
                                thatcopx = self.points.get_event(thatkey,{'time','copx'},stage.limits);
                                % here, it's this minus subsequent that, so find the minimal by time. 
                                cur = 1;
                                while thiscopx.time(1) > thatcopx.time(cur)
                                    cur = cur + 1;
                                end
                                minlength = min(height(thiscopx),height(thatcopx));
                                datcol = abs(thiscopx.copx(1:minlength - cur +1) - thatcopx.copx(cur:minlength));
                            case 'swing_duration'
                                hstimes = self.points.get_event(thiskey,'time',stage.limits).Variables;
                                totimes = self.points.get_event(['TO' upper(side{:}(1))],'time',stage.limits).Variables;
                                % find the first HS that's after the first TO
                                cur = 1;
                                while hstimes(cur) < totimes(1)
                                    cur = cur + 1;
                                end
                                datcol = hstimes(cur:end) - totimes(1:length(hstimes)-cur+1);
                                assert(all(datcol) > 0,'wrong swing');
                            case 'stance_duration'
                                hstimes = self.points.get_event(thiskey,'time',stage.limits).Variables;
                                totimes = self.points.get_event(['TO' upper(side{:}(1))],'time',stage.limits).Variables;
                                % find the first TO that's after the first HS
                                cur = 1;
                                while totimes(cur) < hstimes(1)
                                    cur = cur + 1;
                                end
                                datcol = abs(totimes(cur:end) - hstimes(1:length(totimes) - cur+1));
                            case 'ds_duration'
                                hstimes = self.points.get_event(thiskey,'time',stage.limits).Variables;
                                if strcmp(side{:},'left')
                                    tokey = 'TOR';
                                else
                                    tokey = 'TOL';
                                end
                                totimes = self.points.get_event(tokey,'time',stage.limits).Variables;
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
                for n = 1:length(fnames)
                    name = fnames{n,1};
                    datcol = tmp.(name);
                    stagedata.(name) = [datcol;nan*ones(longest-length(datcol),1)];
                    % next to each pair, add it's symmetries series
                    if endsWith(name,'right')
                        leftname = strrep(name,'right','left');
                        symsname = strrep(name,'right','symmetries');
                        leftcol = tmp.(leftname);
                        % these columns are coordinated by the construction
                        % of the self.basics tables, but the lengths don't
                        % always match. so just take by shortest
                        m = min(length(datcol),length(leftcol));
                        syms = VisHelpers.symmetries([leftcol(1:m),datcol(1:m)]);
                        stagedata.(symsname) = [syms;nan*ones(longest-length(syms),1)];
                    end
                end
                self.basics.(self.stages(s).name) = stagedata;
            end
        end
        
        function export(self)
            warning('off','MATLAB:xlswrite:AddSheet');
            [s,p] = uiputfile([self.subjid '-' self.prepost '.xlsx']);   
            if s ~= 0
                saveto = fullfile(p,s);
                for s=1:self.numstages
                    stagename = self.stages(s).name;
                    writetable(self.basics.(stagename),saveto,'FileType','spreadsheet','Sheet',stagename);
                end
                syshelpers.remove_default_sheets(saveto);
            end
        end
    end
end

