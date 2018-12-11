classdef QualySubject
    %QUALYSUBJECT Process Raziel Treadmill Data
    %   Finds and orders gait events, and exports the data
    properties(Constant)
        partnames = {'before excercise','after exercise','after 1 week'};
        stagenames = {'first 0.5 m/s','1.0 m/s', 'second 0.5 m/s', 'adaptation','post adaptation'};
        split_prompts = {
            'Mark the boundaries of the first three stages',...
            'Mark the boundaries of the adaptation stage',...
            'Mark the boundaries of the post adaptation stage'...
        };
        split_durations  = [360,900,300]; % expected durations of stages in seconds
        numsplits = 8;
        numstages = length(QualySubject.stagenames);
        symmetry_base = 'step length';
   end
    properties
        datafile
        datapath
        subjid
        datarate
        stages
        forces
        stage_boundaries
        visu
        part
    end
    methods(Static)
        function [timings] = StepTimes(start,finish,COPY,Fz)
            % this function takes cleaned COP data from one plate and a global index range
            % and returns step lengths along with their global indices. 
            % Every row represents a leg stance: [ start index i.e HS time,   end index i.e TO time ]
            % start: int starting index for this stage
            % finish: int final index for this stage
            % COPY: COP data from forceplate along Y axis
            lookahead = 10;
            lookbehind = 10;
            thresh = 0.2; % 20cm away from Y = 0
            cur = start - lookbehind;
            steps = 0;
            proportion = 0.65;
            weight = mean(findpeaks(Fz,'MinPeakDistance',100)); %very simplistically
            assert(weight > 300, 'subject is too light ~ 30kg');
            assert(weight < 2000, 'subject is too heavy ~ 200kg');
            halfweight = proportion * weight;
            while cur <= finish
                % initial contact is the first numeric value in step
                % but the COPY at that point is missleading. it is a lot
                % more forwawrd than actual foot location since the subject
                % pushes the place forward. this is why the "halfweight"
                % requirement is imposed.
                while isnan(COPY(cur)) || COPY(cur) < thresh
                    cur = cur + 1;
                end
                
                % found the initial contact, so proper HS is registered 
                % when force on the plate is at least halfweight
                while Fz(cur) < halfweight
                    cur = cur + 1;
                end
                
                step_start = cur;
                
                % scan a lookahead window for all NaN or very small
                step_end = 0;
                while step_end == 0 && cur + lookahead <= finish
                    % reset the end index each time. see comment below.
                    step_end = 0;
                    forward = COPY(cur:cur+lookahead);
                    if all(isnan(forward)) || all(forward < thresh)
                        step_end = cur;
                        % now go back until the force is at least
                        % halfweight
                        while Fz(step_end) < halfweight
                            step_end = step_end - 1;
                        end
                    elseif cur  > finish - lookahead
                        disp(forward);
                        step_end = min(finish,cur + lookahead);
                    end
                    cur = cur + 1;
                end
                
        %         if step_end < step_start
        %             disp(step_end);
        %         end
                
                % if step_end = 0 it means the stage finish mark is in the middle
                % of a step on this plate
                if step_end  > step_start
                    steps = steps + 1;
                    step = COPY(step_start:step_end);
                    [~,mxind] = max(step);
                    [~,mnind] = min(step);
                    if max(step) > min(step)
                        timings(steps,:) = [step_start + mxind,step_start + mnind]; % HS TO
                    else
                        disp(step);
                    end
                end
                cur = cur + 1;
            end
        end
    end
    methods
        function self = QualySubject(datafile,datapath,part)
            %QUALYSUBJECT Constructor:
            %   datafile: !!MUST!! be a .mat output of a Visual3D pipeline created by Anat Shkedy
            %   datpath: its directory
            %   part: 1,2 or 3 as by the relevant experimental session
            subjid = regexp(datafile,'(?<=\-)0{2,3}\d{1,2}','match');
            subjid = subjid{:};
            assert(~isempty(subjid),'the .mat file doesn''t match  the expected name format: c/p-000<NUM>.mat');
            self.subjid = subjid;
            % get from 'raw' the data relevant to chosen 'part'
            access_index = 0;
            raw = load(fullfile(datapath,datafile));
            for f = 1:length(raw.FILE_NAME)
                n = raw.FILE_NAME{f};
                [~,toks] = regexp(n,'(\w+)_part(\d)','match','tokens');
                assert(all(size(toks) == [1,1]),'the .mat file in FILE_NAME doesn''t match  the expected name format:\nID_part<no.>.mat');
                part_by_filename = str2double(toks{1,1}{2});
                if(part == part_by_filename)
                    access_index = f;
                    break;
                end
            end
            assert(access_index > 0,'Could not find which data to take');
            reduce_cells = {'R_COP','L_COP','L_FP','R_FP','FRAME_RATE'};
            for i = 1:length(reduce_cells)
                d = reduce_cells{i};
                eval([d '=  raw.' d '( ' num2str(access_index) ' );']);
            end
            self.datarate = FRAME_RATE{1,1}; %#ok<*IDISVAR,*USENS>

            % order the COP y and Fz in tables
            self.forces.right = array2table([R_FP{1}(:,3),R_COP{1,1}(:,1)],'VariableNames',{'Fz','COPY'});
            self.forces.left = array2table([L_FP{1}(:,3),L_COP{1,1}(:,1)],'VariableNames',{'Fz','COPY'});
            self.datafile = datafile;
            self.datapath = datapath;
            self.part = part;
            self.stages = VisHelpers.initialize_stages(QualySubject.numstages);
            self.part = part;
            clear raw;
        end
        function [matched_lengths] = align_steps(self,stageindex,start)
            % the stage of each side are assumed to be valid -- times are
            % correctly ordered: hs1 < to1 < hs2 < to2 ...
            % stage: 1 x [ RIGHT LEFT ] cell array. 
            % R and L are [ No. Steps ] x [ HS-INDEX LENGTH TO-INDEX] matrices.
            matched_lengths = double.empty(0,2);
            rcop = self.forces.right.COPY;
            lcop = self.forces.left.COPY;
            gi = self.stages(stageindex).gait_indices;

            % recursion stop
            if start >= size(gi.left,1) || start >= size(gi.right,1)        
                return;
            end
            m = 1;

            left = gi.left(start:end,:);
            right = gi.right(start:end,:);
            % 1/2 a second -- maximal allowed time between consecutive lto - rhs and rto - lhs
            % it is A LOT, but this way it balances off the distortion due
            % to step direction...s
            timeprox = self.datarate/2; 
            % find where to start
            % sometimes it's like running, so instead of looking for the left TO
            % right after, look for the closest
            rcur = find(right(:,1) > left(1,2),1);
            % find the closest lto preferably after the found right heel strike
            [~,lcur] = min(abs(left(:,2) - right(rcur,1)));
            % starting at 'cur', cycle through the hs/to data seeking the nearest appropriate entry
            % every time: RHS -> LTO -> LHS -> RTO -> RHS each one must be
            % larger than previous but no larger than next. Stop when end of
            % shorter side is reached.
            % HS in same row. if a mismatch is encountered, register the bad index
            % and recurse starting from the bad.
            isrunning = [];
            while lcur < size(left,1) && rcur < size(right,1)
                rhs = right(rcur,1);
                lto = left(lcur,2);
                lhs = left(lcur + 1,1);
                rto = right(rcur,2);
                % require  small difference between consecutive hs and to
                if all(abs([rto - lhs,lto - rhs])<timeprox)
                    matched_lengths(m,:) = [lcop(lhs) - rcop(rto),rcop(rhs) - lcop(lto)];
                    m = m + 1;
                    % check for strict ordering of rto-lto,rhs-lhs 
                    if rhs > lhs || lto > rto
                        isrunning = [isrunning;[lcur,rcur]];
                    end
                else
                    fprintf('problem at %d left -- %d right:\nRTO: %d\tLHS: %d\tLTO: %d\tRHS: %d\n',...
                        start+lcur,start+rcur,rto,lhs,lto,rhs...
                    );
                    newstart = max([rcur,lcur] + (start+1));
                    if exist('matched_lengths','var')
                        matched_lengths = [matched_lengths;self.align_steps(stageindex,newstart)];
                    else
                        matched_lengths = self.align_steps(stageindex,newstart);
                    end
                    break;
                end
                rcur = rcur + 1;
                lcur = lcur + 1;
            end
            if ~isempty(isrunning)
                warning('these steps look like like running in:');
                disp(isrunning);
            end
        end 
        function self = mark_stages(self)
            % load stage limits from file or get them from user
            % one side is enough since the stage timings are uniform for both plates.
            % the decision to use column 2 of the force data, is completely arbitrary
            [~,base,~] = fileparts(self.datafile);
            boundaries_file = fullfile(self.datapath,[base '-' num2str(self.part) '-boundaries.mat']);
            new = false;
            frate = self.datarate;
            % if found saved boundaries are used
            if exist(boundaries_file,'file')
                tmp = load(boundaries_file);
                ix = tmp.boundaries;
                clear tmp;
            else    
                new = true;
                stage_margin = 30*frate; % 1/2 minute before and after expected start
                ix = zeros(1,QualySubject.numsplits);
                % plot approximate stages and ask user for marks
                for prompt=1:length(QualySubject.split_durations)
                    [latest_point,latest_index] = max(ix);
                    if latest_point == 0
                        latest_index = 0;
                    end
                    figure('units','normalized','outerposition',[0 0 1 1]);
                    from = max(1,latest_point  - stage_margin);
                    to = min(from + (QualySubject.split_durations(prompt)*frate) + stage_margin*2,height(self.forces.right)); 
                    plot(self.forces.right.Fz(from:to));
                    title(QualySubject.split_prompts{prompt});
                    xlabel('minutes');
                    [t,l] = VisHelpers.minutes(1:(to - from),frate);
                    xticks(t);
                    xticklabels(l);
                    grid on;
                    % the user will mark the beginning, speed swaps and finish
                    % of the first three stages in one go -- that's four points
                    if prompt == 1
                        gin = 4;
                    % the adaptation and post adaptation boundaries will be marked
                    % separately -- that's two points for each
                    else
                        gin = 2;
                    end
                    [xs,~] = ginput(gin);
                    ix(latest_index+1:latest_index+gin) = sort(round(xs))' + (from -1);
                    close;
                end
            end
            % show the user the overall segmentation on both sidesfor side=1:2
            for side={'left','right'}
                figure;
                plot(self.forces.(side{:}).Fz);
                title(['Current Boundaries on Fz ' side{:}]);
                hold on;
                for i=1:length(ix)
                    b = ix(i);
                    line([b,b],get(gca,'YLim'),'color','black','LineWidth',2,'Linestyle', '--');
                end
                hold off;
            end
            proceed = input('do you aprove these boundaries [y/n]? ','s');
            if ~strcmp('y',proceed)
                error('operation aborted');
            else
                close all;
            end
            if new
                saveit = input('save the marked stage boundaries [y/n]? ', 's');
                if strcmp(saveit,'y')
                    boundaries= ix;  %#ok<NASGU>
                    save(boundaries_file,'boundaries');
                end
            end
            self.stage_boundaries = ix;
        end


        function self = find_gait_events(self)
            %FIND_GAIT_EVENTS 
            %   locate the indices of heel strikes and toe offs 
            for side = {'left','right'}
                fz = self.forces.(side{:}).Fz;
                COP = self.forces.(side{:}).COPY;
                stage = 1;
                for boundary = 1:self.numsplits
                    % since the first three stages are back to back, while the last
                    % two have a break before them, the stages are 1-2,2-3,3-4,5-6,7-8
                    % this if statement catches 2,3,4,6 and 8
                    if (boundary > 1 && boundary < 5) || mod(boundary,2) == 0
                        s = self.stage_boundaries(boundary-1);
                        e = self.stage_boundaries(boundary);
                        self.stages(stage).gait_indices.(side{:}) = QualySubject.StepTimes(s,e,COP,fz);
                        stage = stage + 1;
                    end
                end
            end
        end

        function self = compile_stages(self)
            for  s = 1:QualySubject.numstages
                stage = self.stages(s);
                name = QualySubject.stagenames{s};
                fprintf('\n Aligning HS/TO times for %s\n',name);
                stage.step_lengths  = self.align_steps(s,1);
                numsteps = size(stage.step_lengths,1);
                fprintf('found %d matching steps out of %d left and %d right\n',numsteps,size(self.stages(s).gait_indices.left,1),size(self.stages(s).gait_indices.right,1));
                if s <= 3
                    stage.include_inbaseline = true;
                else
                    stage.fit_curve = true;
                    stage.perturbation_magnitude = 2;
                    % the faster belt was always the right one.
                    % the magnitude is 1/0.5 and the expected sign for the
                    % adaptation is -1 (curve goes down, left is longer
                    % than right)
                    if s==4
                        % adaptation
                        stage.expected_sign = -1;
                    else % de-adaptation
                        stage.expected_sign = 1;
                    end
                end
                stage.name = name;
                self.stages(s) = stage;
            end
        end
        function self = get_visualizer(self)
            % make specs for the visualizer
            specs = struct;
            specs.name = QualySubject.symmetry_base;
            specs.stages = self.stages;
            conf = yaml.ReadYaml('conf.yml');
            specs.fit_parameters = conf.Qualysis;
            specs.titlesprefix = [self.subjid ' ' QualySubject.partnames{self.part}];
            self.visu = VisHelpers(specs);
        end
        function save_step_lengths(self)
            stepsfilename = [self.subjid '_part' num2str(self.part) '_steplengths.mat'];
            [sfile,spath] = uiputfile(fullfile(self.datapath,stepsfilename),'Save the Step Length Data');
            if sfile
                stagedat = self.stages; %#ok<NASGU>
                save(fullfile(spath,sfile),'stagedat');
            end
        end
        function export_learning_data(self,ltimes)
            exportfilename = [self.subjid '_part' num2str(self.part) '_' self.model '_learning.csv'];
            fid = fopen(fullfile(self.datapath,exportfilename),'wt');
            lnames = fieldnames(ltimes);
            fprintf(fid,'stage,learning time,learning steps,r^2,first 5,last 30');
            for lt = 1:length(lnames)
                dat = ltimes.(lnames{lt});
                paramnames = fieldnames(dat.params);
                if lt == 1
                    fprintf(fid,',%s\n',strjoin(paramnames,','));
                end
                paramvalues = [];
                for i = 1:length(paramnames)
                    paramvalues = [paramvalues,dat.params.(paramnames{i})];
                end
                s = find(strcmp(strrep(lnames{lt},'_',' '),QualySubject.stagenames),1);
                lhs = self.stages(s).gait_indices.left(:,1);
                time = round((lhs(dat.split) - lhs(1))/self.datarate,2);
                steps = 2*dat.split;
                fprintf(fid,'%s,%f,%d,%f,%f,%f',lnames{lt},time,steps,dat.quality,dat.mf5,dat.ml30);
                fprintf(fid,repmat(',%f',1,length(paramnames)),paramvalues);
                fprintf(fid,'\n');
            end
            fclose(fid);
        end
    end
end
