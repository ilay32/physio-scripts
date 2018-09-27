classdef GaitEvents
    % given a directory, this class provides some methods for
    % gait analysis of the data in it.
    properties (Constant)
        cycles_filename = 'GaitCycleParameters.csv'; % assuming no one changed file names...
        forces_filename = '2 ForcePlateResults @0.5 kHz.csv'; % note that it will always say 0.5Hz regardless of the actual datrate of the export
    end
    properties
        datarate
        datafolder
        reversed
        forces
        cycles
        datastarts
        datalength
        subjid
        stages
        numstages
        protocol
        stage_reject_message
        abort;
    end
    methods (Static)
        function c = cv(s)
            c =  100*nanstd(s)/abs(nanmean(s));
        end
        function c = iqr(s)
            qs = quantile(s,0.25:0.25:0.75);
            c = 100*(qs(3) - qs(1))/qs(2);
        end
        function c = medcv(s)
            ms = median(s);
            m = median(abs(s - ms));
            c = 100*m/ms;
        end         
    end
    methods
        function self = GaitEvents(folder,subjectpattern)
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
            self.abort = false;
            subjmatch = regexp(folder,subjectpattern,'match');
            if isempty(subjmatch)
                self.subjid = 'IDUNMATCHED';
            else
                self.subjid = strrep(subjmatch{:},'\','_');
            end
            self = self.load_forces();
            self = self.load_cycles();
            self.datastarts = self.forces.time(1);
            self.datalength = size(self.forces.Variables,1);
            self.reversed = length(find(self.cycles.width < 0)) > length(find(self.cycles.width > 0));
            self.stage_reject_message = 'mark stages [y/n]?';
        end
        function self = load_forces(self)
            forcesfile = fullfile(self.datafolder,GaitEvents.forces_filename);
            if ~exist(forcesfile,'file')
                zips = dir([self.datafolder '\*.zip']);
                if size(zips,1) == 1
                    disp('unzipping the data...');
                    unzip(fullfile(zips(1).folder,zips(1).name),self.datafolder);
                end
            end
            f = importdata(forcesfile);
            self.datarate = 1/(f.data(2,1) - f.data(1,1)); % Hz
            self.forces = array2table(f.data,'VariableNames',{'time','fz','copx','copy'});
        end
        function self = load_cycles(self)
            self.cycles = false;
            cycfile = fullfile(self.datafolder,GaitEvents.cycles_filename);
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
            self.cycles = ctable;
        end
        
        function self = read_protocol(self,protfilename)
            fp = fullfile(self.datafolder,protfilename);
            if ~exist(fp,'file')
                warning('could not find the protocol file. please save an appropriate %s in %s',...
                    self.datafolder,protfilename...
                );
            end
            pid = fopen(fp);
            c = textscan(pid,'%f;%f;%f');
            times = c{:,1};
            speeds = [c{:,2},c{:,3}];
            fclose(pid);
            self.protocol = array2table([speeds,times],'VariableNames',{'speedL','speedR','onset_time'});
        end
        
        function self = mark_stages(self,offset)
            %MARKSTAGES dliniate experiment stages
            % let the user mark the begining and end of every
            % stage in the trial manually. offset should be given in
            % readings.
            ready = isa(offset,'char') && strcmp(offset,'ready');
            if isempty(self.protocol)
                warning('must load protocol first');
                return;
            end
            if isempty(self.stages)
                warning('must resolve stages first');
                return
            end
            if ready
                chunks = reshape(extractfield(self.stages,'limits'),[2,self.numstages])';
            else
                chunks = [self.protocol.onset_time(2:2:end)';self.protocol.onset_time(3:2:end)']';
            end
            h = figure('name',self.datafolder);
            plot(self.forces.fz);
            VisHelpers.minutize_axes(self.datalength,self.datarate);
            lines = {};
            function set_boundaries(~,~,~)
                allboundaries = [];
                for li=lines
                    pos = li.getPosition();
                    allboundaries = [allboundaries;pos(1)];
                end
                allboundaries = sort(allboundaries);
                allboundaries = reshape(allboundaries,[2,size(allboundaries,1)/2]);
                for i=1:size(allboundaries,2)
                    self.stages(i).limits = allboundaries(:,i)';
                end
                close;
            end
            
            for s=1:size(chunks,1)
                chunk = chunks(s,:); % in seconds
                if ~ready
                    
                    chunk = chunk * self.datarate; % seconds to readings
                    chunk = chunk + [-10*self.datarate,10*self.datarate];  % 10 seconds before and after presumed limits
                    if nargin == 2
                        chunk = chunk + offset - chunks(1)*self.datarate;
                    end
                    chunk(1) = max(chunk(1),1);
                    chunk(2) = min(chunk(2),self.datalength);
                    chunk = round(chunk);
                end
                for boundary=chunk
                    l = imline(gca,[boundary,boundary],ylim);
                    setColor(l,'black');
                    fcn = makeConstrainToRectFcn('imline',get(gca,'XLim'),get(gca,'YLim'));
                    setPositionConstraintFcn(l,fcn);
                    lines = [lines,l];
                end  
                %[limits,~] = ginput(2);
                %limits = sort(limits) + chunk(1);
                %self.stages(s).limits = limits;
            end
            uicontrol(h,'String', 'done', 'callback', @set_boundaries);
            uiwait(h);
        end
        function self = confirm_stages(self)
            figure('name',self.datafolder);
            title('Please confirm that the stage boundaries');
            plot(self.forces.fz);
            VisHelpers.minutize_axes(self.datalength,self.datarate);
            hold on;
            for s=1:self.numstages
                limits = self.stages(s).limits;
                for l=1:2
                    line([limits(l),limits(l)],get(gca,'YLim'),'color','black','LineWidth',2,'Linestyle', '--');
                end
            end
            uicontrol('String','Confirm','Callback','uiresume(gcf)',...
                'Position',[10 10 50 30]);
            uicontrol('String','Reject','Callback',@self.stages_rejected,...
                'Position',[100,10,50,30]);
            uiwait(gcf);
            close;
        end
        function stages_rejected(self,~,~,~)
            global goon;
            uiresume(gcf);
            close;
            proceed = input(self.stage_reject_message,'s');
            if ~strcmp(proceed,'y')
                goon = false;
                %error('aborting. sort it out and start over');
            end
        end
    end
end