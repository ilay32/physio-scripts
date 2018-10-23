classdef NirsOrderer
    %NIRSORDERER groups NIRS data by events and conditions
    %   takes HOMER-processed data (.nirs) and chunks it by event and condition
    %   can plot the event timings and export the chunks to excel
    properties(Constant)
       uniwalklength = 20; %??
       baseline_duration = 5; %seconds
       event_colors = {'red','green','black','blue','magenta','cyan','yellow'};
       testlength = 20;
       export_scale_factor = 1000000;
    end
    methods(Static)
        function longer = spline_stretch(shorter,stretchto)
            % expects column vector(s)
            rows = size(shorter,1);
            columns = size(shorter,2);
            longer = zeros(stretchto,columns);
            for c=1:columns
                sp = spline(1:rows,shorter(:,c));
                longer(:,c) = ppval(sp,(1:stretchto)');
            end
        end
    end
    properties
        inputdat
        datarate
        source
        conditions
        event_times
        source_folder
        channels
        test_matrix
    end
    methods
        function self = NirsOrderer(path,nirsfile)
            %NIRSORDERER Construct an instance of this class
            %   Input: full path to the .nirs file holding the data
            self.source = nirsfile;
            self.source_folder = path;
            self.inputdat = load(fullfile(path,nirsfile),'-mat');
            self.conditions = cellfun(@(c)strrep(c,'-','_'),self.inputdat.CondNames,'UniformOutput',false);
            self.datarate = 1/mean(diff(self.inputdat.t));
            self = self.read_export();
            disp('HOMER Processing Parameters:');
            disp(self.inputdat.procInput.procParam);
        end
        
        function self = learn_events(self)
            % gather event timings by name
            events = table(); 
            for event_index=1:size(self.conditions,2)
                times = find(self.inputdat.s(:,event_index)==1);
                for t=1:length(times)
                    %n = strrep(self.inputdat.CondNames(event_index),'-','_');
                    events = [events;{times(t),self.conditions(event_index)}];
                end
            end
            events.Properties.VariableNames =  {'time','name'};
            self.event_times = sortrows(events,'time');
        end
        
       
        function self = read_export(self)
            % this will read the first lines of the .txt export
            % and will make sure that the correct data is produced for
            % every channel
            fid = fopen(fullfile(self.source_folder,strrep(self.source,'.nirs','.txt')));
            channels = regexp(fgetl(fid),'S\d_D\d_Hb(R|O)','match');
            assert(~isempty(channels),'could not read text export');
            test = nan*ones(20,length(channels));
            for i=1:NirsOrderer.testlength
                row = sscanf(fgetl(fid),'%f\t');
                test(i,:) = row(2:end);
            end
            fclose(fid);
            self.channels = channels;
            self.test_matrix = test;
        end
        function d = fetch_data(self)
            src = self.inputdat.procResult.dc;
            dlength = size(src,1);
            dwidth = size(src,3);
            raw1 = src(:,1,:);
            raw1 = fliplr(reshape(raw1,[dlength,dwidth]));            
            if length(self.channels) == dwidth
                d = raw1;
            else
                if length(self.channels) == dwidth*2
                    warning('text export contains %d columns instead of 6 (only HbO or HbR) or 12 (both).\n')
                end
                raw2 = src(:,2,:);
                raw2 = fliplr(reshape(raw2,[dlength,dwidth]));
                d = [raw1,raw2];
            end
            precision = 1/NirsOrderer.export_scale_factor;
            d = d*NirsOrderer.export_scale_factor;
            test = reshape(abs(d(2:NirsOrderer.testlength+1,:) - self.test_matrix),1,numel(self.test_matrix));
            assert(sum(test)/numel(test) < precision...
                && max(test) < precision,... 
                'missmatch between .nirs data and .txt export\nmax diff: %d, mean diff: %f',max(test),mean(test));           
            clear src;
        end
        function export_walks(self)
            % output the data by these guidlines:
            % baseline of walk is 5 seconds of standing before
            % distractor/letters onset. all data is centered around the
            % baseline average. the walk part itself is normalized by
            % NirsOrddrer.spline_stretch. data is saved in one excel file
            % with four tabs corresponding to the four walking conditions.
            % every tab holds a 6 channels x 6 walks matrix
            data = self.fetch_data();
            export = struct;
            for r=1:height(self.event_times)
                row = self.event_times(r,:);
                if(~isempty(regexp(row.name{:},'^(E|F|S)$','match'))) % event is 'E' 'F' or 'S' -- skip
                    continue;
                end
                nextrow = self.event_times(r+1,:); % !!CAUTION!! assuming there is a next one since this excludes the sitting part of the experiment
                walk_start = row.time;
                base_start = walk_start - 14*self.datarate;
                base_end = base_start + 5*self.datarate;
                center = mean(data(base_start:base_end,:));
                prewalk = data(base_start:base_end,:) - center;
                % normalize the walk duration by interpolation
                walk = NirsOrderer.spline_stretch(data(walk_start+1:nextrow.time,:),NirsOrderer.uniwalklength*self.datarate);
                if any(strcmp(fieldnames(export),row.name{:}))
                    export.(row.name{:}) = [export.(row.name{:}),{{prewalk,walk}}];
                else
                    export.(row.name{:}) = {{prewalk,walk}};
                end
            end
            outfile = fullfile(self.source_folder,strrep(self.source,'.nirs','.xlsx'));
            sheets = fieldnames(export);
            for s=1:length(sheets)
                [t,r] = self.make_table(export.(sheets{s}));
                writetable(t,outfile,'Sheet',sheets{s},'Range','A2','WriteVariableNames',false);
                xlswrite(outfile,r,sheets{s},'A1');
            end
        end
        function [t,r] = make_table(self,blocks)
            pres = [];
            walks = [];
            header = {};
            for block=blocks
                pres = [pres,block{:}{1},nan*ones(size(block{:}{1},1),2)];
                walks = [walks,block{:}{2},nan*ones(size(block{:}{2},1),2)];
                header = [header,self.channels,{' ',' '}];
            end
            t = array2table([pres;nan*ones(2,size(pres,2));walks]);
            r = header;
        end
        function plotevents(self)
            d = self.inputdat.d(:,1);
            plot(d);
            hold on;
            fns = self.conditions;
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
            legend(lh,cellfun(@(c)strrep(c,'_',' '),fns,'UniformOutput',false));
            %legend(lh,fns);
            hold off;
        end
    end
end

