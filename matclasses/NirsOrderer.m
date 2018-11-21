classdef NirsOrderer
    %NIRSORDERER groups NIRS data by events and conditions
    %   takes HOMER-processed data (.nirs) and chunks it by event and condition
    %   can plot the event timings and export the chunks to excel
    properties(Constant)
       uniwalklength = 13;
       baseline_duration = 5; %seconds
       event_colors = {'red','green','black','blue','magenta','cyan','yellow'};
       testlength = 20;
       export_scale_factor = 1000000;
       midwalk_range= 5;
    end
    methods(Static)
        function unified = spline_unify(orig,unilength)
            % expects column vector(s)
            rows = size(orig,1);
            columns = size(orig,2);
            unified = zeros(unilength,columns);
            for c=1:columns
                %sp = spline(1:rows,shorter(:,c));
                unified(:,c) = spline(1:rows,orig(:,c),1:rows/unilength:rows);%ppval(sp,(1:stretchto)');
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
        text_channels
        test_matrix
        nirs_channels
    end
    methods
        function self = NirsOrderer(path,nirsfile)
            %NIRSORDERER Construct an instance of this class
            %   Input: full path to the .nirs file holding the data
            self.source = nirsfile;
            self.source_folder = path;
            self.inputdat = load(fullfile(path,nirsfile),'-mat');
            self.nirs_channels = string();
            ml = 'ml';
            if ~any(strcmp(fieldnames(self.inputdat),ml))
                ml = 'mL';
            end
            cdefs = self.inputdat.(ml);
            for cdef=1:size(cdefs,1)
                oxy = 'HbO';
                if cdefs(cdef,4) == 2
                    oxy = 'HbR';
                end
                self.nirs_channels(cdef) = ['S' num2str(cdefs(cdef,1)) '_D' num2str(cdefs(cdef,2)) '_' oxy];
            end
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
            events = sortrows(events,'time');
            % sometimes events are somehow doubled in short succession
            % catch this cases and take the middle value as correct
            % condition is twice the same name and less the 2sec between.
            for row=1:height(events)-1
                if height(events) <= row
                    % this can happen since rows get deleted
                    break;
                end
                thisrow = events(row,:);
                nextrow = events(row+1,:);
                if ~isempty(regexp(thisrow.name{:},'^(E|F|S)$','match'))
                    continue;
                end
                if strcmp(thisrow.name,nextrow.name)
                    fprintf('double event found (%s):\n\tplace:%d,%d,time difference:%.3f seconds\n',...
                        thisrow.name{:},row,row+1,(nextrow.time- thisrow.time)/self.datarate);
                    if nextrow.time - thisrow.time < 2*self.datarate
                        fprintf('using middle value\n\r');
                        mid = [thisrow.time+round(nextrow.time-thisrow.time),thisrow.name];
                        events(row,:) = mid;
                        events(row+1,:) = [];
                    else
                        error('that''s too long. please check the data. aborting\n\r');
                    end
                end
            end
            self.event_times = events;
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
            self.test_matrix = test;
            numOx = sum(cell2mat(regexp(channels,'.*HbO.*')));
            numDox = sum(cell2mat(regexp(channels,'.*HbR.*')));
            nc = self.nirs_channels;
            if ~all(strcmp(channels,[fliplr(nc(1:numOx)),fliplr(nc(numOx+1:numOx+numDox))]))
                disp('channel missmatch');
            end
            self.text_channels = channels;
        end
        function d = fetch_data(self)
            src = self.inputdat.procResult.dc;
            dlength = size(src,1);
            dwidth = size(src,3);
            raw1 = src(:,1,:);
            raw1 = fliplr(reshape(raw1,[dlength,dwidth]));            
            if length(self.text_channels) == dwidth
                d = raw1;
            else
                if length(self.text_channels) ~= dwidth*2
                    warning('text export contains %d columns instead of 6 (only HbO or HbR) or 12 (both).\n',length(self.text_channels))
                end
                raw2 = src(:,2,:);
                raw2 = fliplr(reshape(raw2,[dlength,dwidth]));
                d = [raw1,raw2];
            end
            precision = 1/NirsOrderer.export_scale_factor;
            d = d*NirsOrderer.export_scale_factor;
            test = reshape(abs(d(1:NirsOrderer.testlength,:) - self.test_matrix),1,numel(self.test_matrix));
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
            % NirsOrddrer.spline_unify. data is saved in one excel file
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
                base = data(base_start:base_end,:) - center;
                prewalk = data(base_end+1:walk_start,:) - center;
                % normalize the walk duration by interpolation
                walk_length = nextrow.time - walk_start;
                u = NirsOrderer.uniwalklength*self.datarate;
                if walk_length > 1.5*u || walk_length < u/1.5
                    fprintf('deviant walk duration: %.2f seconds at no. %d (%s)\n',walk_length/self.datarate,r,row.name{:})
                end
                walkraw = data(walk_start+1:nextrow.time,:) - center;
                walk = NirsOrderer.spline_unify(walkraw,u);
                if any(strcmp(fieldnames(export),row.name{:}))
                    export.(row.name{:}) = [export.(row.name{:}),{{base,prewalk,walk}}];
                else
                    export.(row.name{:}) = {{base,prewalk,walk}};
                end
            end
            outfile = fullfile(self.source_folder,strrep(self.source,'.nirs','.xlsx'));
            sheets = fieldnames(export);
            if exist(outfile,'file')
                delete(outfile);
            end
            warning('off','MATLAB:xlswrite:AddSheet');
            for s=1:length(sheets)
                [t,r] = self.make_table(export.(sheets{s}));
                writetable(t,outfile,'Sheet',sheets{s},'Range','A2','WriteVariableNames',false);
                xlswrite(outfile,r,sheets{s},'A1');
            end
            self.midwalk_averages(outfile,export);
            syshelpers.remove_default_sheets(outfile);
        end
        function midwalk_averages(self,filename,export_data)
            conds = fieldnames(export_data);
            current_row = 1;
            sheet = 'mid-walk-averages';
            for c = 1:length(conds)
                xlswrite(filename,[conds{c},self.text_channels],sheet,['A' num2str(current_row)]);
                current_row = current_row + 1;
                walks  = export_data.(conds{c});
                averages = nan*ones(length(walks),length(self.text_channels));
                for w = 1:length(walks)
                    walk = walks{w}{3};
                    middle = size(walk,1)/2;
                    twosecs = (NirsOrderer.midwalk_range/2)*self.datarate;
                    averages(w,:) = mean(walk(round(middle - twosecs):round(middle + twosecs),:)); 
                    xlswrite(filename,{['walk ' num2str(w)]},sheet,['A' num2str(current_row + w - 1)]);
                end
                xlswrite(filename,averages,sheet,['B' num2str(current_row)]);
                current_row = current_row + size(averages,1);
                xlswrite(filename,nan*ones(2,size(averages,2)+1),sheet,['A' num2str(current_row)]);
                current_row = current_row + 2;
            end
        end
        function [t,r] = make_table(self,blocks)
            bases = [];
            pres = [];
            walks = [];
            header = {};
            for b=1:length(blocks)
                block = blocks{b};
                bases = [bases,block{1},nan*ones(size(block{1},1),2)];
                pres = [pres,block{2},nan*ones(size(block{2},1),2)];
                walks = [walks,block{3},nan*ones(size(block{3},1),2)];
                header = [header,self.text_channels,{['walk ' num2str(b)],' '}];
            end
            t = array2table([bases;nan*ones(2,size(bases,2));pres;nan*ones(2,size(pres,2));walks]);
            r = header;
        end
        function plotevents(self)
            d = self.inputdat.procResult.dc(:,2,1);
            plot(d);
            title(['data from ' self.source]);
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

