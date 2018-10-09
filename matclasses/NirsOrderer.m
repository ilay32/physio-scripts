classdef NirsOrderer
    %NIRSORDERER groups NIRS data by events and conditions
    %   takes HOMER-processed data (.nirs) and chunks it by event and condition
    %   can plot the event timings and export the chunks to excel
    properties(Constant)
       uniwalklength = 20; %??
       baseline_duration = 5; %seconds
       event_colors = {'red','green','black','blue','magenta','cyan','yellow'};
    end
    methods(Static)
        function longer = spline_stretch(shorter)
            % expects column vector(s)
            rows = size(shorter,1);
            columns = size(shorter,2);
            lrows = NirsOrderer.uniwalklength;
            longer = zeros(lrows,columns);
            for c=1:columns
                sp = spline(1:rows,shorter(:,c));
                longer(c,:) = ppval(sp,(1:lrows)');
            end
        end
    end
    properties
        inputdat
        source
        event_times
        event_names
        source_folder
    end
    methods
        function self = NirsOrderer(path,nirsfile)
            %NIRSORDERER Construct an instance of this class
            %   Input: full path to the .nirs file holding the data
            self.source = nirsfile;
            self.source_folder = path;
            self.inputdat = load(fullfile(path,nirsfile),'-mat'); 
        end
        
        function self = learn_events(self)
            % gather event timings by name
            events = table(); 
            for event_index=1:size(self.inputdat.CondNames,2)
                times = find(self.inputdat.s(:,event_index)==1);
                for t=1:length(times)
                    %n = strrep(self.inputdat.CondNames(event_index),'-','_');
                    events = [events;{times(t),self.inputdat.CondNames(event_index)}];
                end
            end
            events.Properties.VariableNames =  {'time','name'};
            self.event_times = sortrows(events,'time');
        end
        
        function chunk_data(self)
            data = self.inputdat.procResult.dc(:,1,:);
            data = reshape(data,[size(data,1),size(data,3)]);
            chunks = [];
            e = self.event_times;
            % loop the S event and register the chunks
            chunks_index = 1;
            for t=1:length(e.S)
                current_cond = self.next_event(e.S(t),'S');
                % from S look one forward to get the wait block
                %wait = struct;
                current_cond.data = data(t:current_cond.time,:);
                %wait.details = current_cond;
                current_cond.type = 'wait';
                current_cond.global_index = chunks_index;
                chunks = [chunks,current_cond];
                chunks_index = chunks_index + 1;

                % from the next, look one forward to get the walk chunk
                next_cond = next_event(current_cond.time,current_cond.name,event_times);
                if ~isempty(next_cond)
                    %walk = struct;
                    next_cond.data = data(current_cond.time:next_cond.time);
                    %current_cond.details = next_cond;
                    next_cond.type = 'walk';
                    next_cond.global_index = chunks_index;
                    chunks = [chunks,next_cond];
                    chunks_index = chunks_index + 1;
                end
            end
        end
        function e = next_event(etime,ename)
            % this function takes time index of an event as 'etime' and the name of that event, as by the input data,
            % and returns a struct representing the subsequent event
            e = struct;
            etimes = self.event_times;
            % loop the event times to find the next one
            nextTime = inf;
            fns = self.inputdat.CondNames;
            nextName = fns{1};
            for f=1:length(fns)
                fn = fns{f};
                % skip if same -- can happen with 's'
                if strcmp(ename,fn)
                    continue;
                end
                in_current_ind = find(etimes.(fn) > etime,1);
                if isempty(in_current_ind)
                    continue;
                end
                next_in_current_event = etimes.(fn)(in_current_ind);
                if(next_in_current_event < nextTime)
                    nextTime = next_in_current_event;
                    nextName = fn;
                end
            end
            if(nextTime == inf)
                e = [];
                return;
            end
            e.name = nextName;
            e.shoes = 'normal';
            if(strfind(nextName,'RS_') == 1)
                e.shoes = 'RS';
            end
            e.time = nextTime;
            e.sitting = logical(strcmp(fn,'F'));
            e.distractor = 'without';
            if(e.sitting || length(strfind(fn,'dual')) > 0) %#ok<ISMT>
                e.distractor = 'with';
            end
        end
        function export_walks(self)
            % output the data by these guidlines:
            % baseline of walk is 5 seconds of standing before
            % distractor/letters onset. all data is centered around the
            % baseline average. the walk part itself is normalized by
            % NirsOrddrer.spline_stretch. data is saved in one excel file
            % with four tabs corresponding to the four walking conditions.
            % every tab holds a 6 channels x 6 walks matrix
            data = self.inputdat.procResult.dc(:,1,:);
            data = reshape(data,[size(data,1),size(data,3)]);
         
            exp = struct;
            for r=1:height(self.event_times)
                row = self.event_times(r,:);
                if(~isempty(regexp(row.name{:},'^(E|F|S)$','match'))) % event is 'E' 'F' or 'S' -- skip
                    continue;
                end
                nextrow = self.event_times(r+1,:); % !!CAUTION!! assuming there is a next one since this excludes the sitting part of the experiment
                walk_start = row.time;
                base_start = walk_start - 14*self.datarate;
                base_end = base_start + 5*self.datarate;
                center = mean(data(base_start:base_end,:),2);
                prewalk = data(base_start:walk_start,:) - center;
                % normalize the walk duration by interpolation
                walk = NirsOrderer.spline_stretch(data(walk_start+1:nextrow.time,:));
                exp.(row.name) = [exp.(row.name),{prewalk,walk}];
            end
            outfile = fullfile(self.source_folder,strrep(self.source,'.nirs','.xlsx'));
            for sheet=fieldnames(exp)
                writetable(outfile,sheet,self.make_table(exp.(sheet{:})));
            end
        end
        function plotevents(self)
            d = self.inputdat.d(:,1);
            plot(d);
            hold on;
            fns = self.inputdat.CondNames;
            for i=1:length(fns)
                color = NirsOrderer.event_colors{i};
                erows = self.event_times(strcmp(self.event_times.name,fns{i}),:);
                times = erows.time;
                lines = {};
                for j=1:length(times)
                    lines{j} = line([times(j),times(j)],get(gca,'Ylim'),'color',color);
                end
                lh(i) = lines{:};
            end
            %legend(lh,cellfun(@(c)strrep(c,'_',' '),fns,'UniformOutput',false));
            legend(lh,fns);
            hold off;
        end
    end
end

