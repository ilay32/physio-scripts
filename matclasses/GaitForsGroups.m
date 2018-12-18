classdef GaitForsGroups
    %GAITFORSGROUPS Basic wrapper for GaitFors Treadmill Data Group
    %Analysis Classes (restep/salute)
    %   The child classes are supposed to implement:
    %        constructor,
    %        agg_dir
    %        baseline_stage
       
    
    properties
        datafolder
        groups
        data_names
        conf
    end
    
    methods
        function self = GaitForsGroups(rootfolder)
            self.datafolder = rootfolder;
        end
        function  main(self,please_process,base,action)
            %MAIN the purpose of this class
            %   'action' cab be either 'flat_averages' for gathering per-subject symmetries data
            %   or 'joint_symmetries' for curve-analysis of symmetries
            %   averaged across subjects
            %   in both cases the data is treated separately by group, as
            %   determined by the agg_dir method
            collected = struct;
            for g1 = 1:length(self.groups{1})
                n1 = self.groups{1}{g1};
                for g2 = 1:length(self.groups{2})
                    n2 = self.groups{2}{g2};
                    fprintf('gathering %s & %s %s data\n',n1,n2,base)
                    key = lower([n1 '_' n2]);
                    gists = self.agg_dirs(n1,n2);
                    if isempty(gists)
                        disp('no data found');
                        continue;
                    end
                    if strcmp(action,'flat_averages')
                        for s=please_process
                            dat = zeros(0,length(self.data_names));
                            for d=1:length(gists)
                                row = self.subject_data(fullfile(gists(d).folder,gists(d).name),s{:},base);
                                if any(row)
                                    dat = [dat;row];
                                end
                            end
                            if any(dat)
                                row = cell(1,size(dat,2));
                                for i=1:length(row)
                                    col = dat(:,i);
                                    row{i} = sprintf('%.5f (std: %.5f, no. subjects %d)',mean(col),std(col),sum(~isnan(col)));
                                end
                                collected.(key).(s{:}) = row;
                            end
                                
                        end
                    elseif strcmp(action,'joint_symmetries')
                        stage_names = self.conf.constants.stagenames.(n2);
                        numstages = length(stage_names);
                        % loop the found data saved by the GaitForceEvents
                        % object
                        allsyms = cell(1,length(gists));
                        for d=1:length(gists)
                            load(fullfile(gists(d).folder,gists(d).name)); %#ok<LOAD>
                            %stage_names = self.get_stage_names(gists(d).folder,n1,n2);

                            ustages = cell(1,numstages);
                            
                            if ~exist('gist','var')
                                disp(gists(d));
                            end
                            % loop the stages to collect symmetries and
                            % baseline means
                            for s=1:numstages
                                %first, if it's salute both_sessions, pick
                                %the name to use or skip
                                gistkey = stage_names{s};
                                if isa(self,'SaluteGroups') && strcmp(n2,'both_sessions')
                                    prepost = regexpi(gists(d).folder,'(pre|post|day[12])','match');
                                    assert(~isempty(prepost),'this gist file seems to be mislocated')
                                    prepost = lower(prepost{:});
                                    if strcmp(gistkey,'normal')
                                        gistkey = self.conf.constants.group_baseline_stage.(prepost).name;
                                    elseif regexp(gistkey,'adaptation','ONCE') && strcmp(prepost,'post')
                                        gistkey = strrep(gistkey,'adaptation','salute');
                                    end
                                end
                                if ~any(strcmp(fieldnames(gist.basics),gistkey))
                                    warning('%s saved data does not include %s. skipping',gists(d).folder,gistkey);
                                    continue;
                                end
                                syms = gist.basics.(gistkey).data.([base '_symmetries']);

                                % you can't add them up if some are
                                % supposed to be up-trend while some
                                % down-trend. so the expected sign is set
                                % arbitrarily to 1 on (re)adaptation and -1 on post_adaptation, 
                                % and if it was the other way around, flip
                                % the symmetries and the expected sign
                                if strcmp(self.conf.fit_parameters.direction_strategy,'expected')
                                    sdetails= gist.basics.(gistkey).symmetry_details;
                                    % so case 1: post_adaptation on 1,
                                    % change to -1
                                    if sdetails.isfitcurve && startsWith(gistkey,'post') && sdetails.expected_sign == 1
                                        syms = -1*syms;
                                    elseif sdetails.isfitcurve && sdetails.expected_sign == -1
                                        syms = -1*syms;
                                    end
                                % same reasoning for empiric strategy...
                                elseif strcmp(self.conf.fit_parameters.direction_strategy,'empiric')
                                    [trend,~,~,~,~] = regress(syms,[ones(length(syms),1),(1:length(syms))']);
                                    if sign(trend) == -1
                                        syms = -1*syms;
                                    end
                                end
                                if self.conf.constants.group_baseline_stage.(n2).index == s
                                    bmean = nanmean(syms(end-min(length(syms)-1,30):end));
                                end
                                ustages{s} = syms;
                            end
                            
                            
                            %bmean = mean(bmeans);
                            % loop stages again to normalize by baseline
                            for s=1:numstages
                                ustages{s} = ustages{s}/abs(bmean);
                                ustages{s} = ustages{s};
                            end
                            clear gist;
                            allsyms{d} = ustages;
                        end
                        % double loop all symmetries to find the shortest
                        % in each stage
                        shortest = inf*ones(1,numstages);
                        for s=1:numstages
                            for d=1:length(allsyms)
                                if ~isempty(allsyms{d}{s}) && length(allsyms{d}{s}) < shortest(s)
                                    shortest(s) = length(allsyms{d}{s});
                                end
                            end
                        end
                        stages_with_data =~isinf(shortest);
                        shortest = shortest(stages_with_data);
                        numstages = sum(stages_with_data);
                        stage_names = stage_names(stages_with_data);
                        
                        % and finally, construct the visualizer
                        specs = struct;
                        stages = VisHelpers.initialize_stages(numstages);
                        specs.fit_parameters = self.conf.fit_parameters;
                        for s=1:numstages
                            stagesyms = [];
                            for d=1:length(allsyms)
                                if ~isempty(allsyms{d}{s})
                                    stagesyms = [stagesyms,allsyms{d}{s}(1:shortest(s))];
                                end
                            end
                            name = stage_names{s};
                            if startsWith(name,'post')
                                stages(s).expected_sign = -1;
                            elseif regexp(name,'adaptation','ONCE')
                                stages(s).expected_sign = 1;
                            end
                            stages(s).data = nanmean(stagesyms,2);
                            if strcmp(self.conf.fit_parameters.model,'dual')
                                stages(s).data = stages(s).data / max(stages(s).data);
                            end
                            stages(s).name = name;
                            if isempty(regexp(name,'adaptation','ONCE'))
                                stages(s).include_inbaseline = true;
                            else
                                stages(s).fit_curve = true;
                                stages(s).perturbation_magnitude = GaitForceEvents.perturbation_magnitude;
                            end
                        end
                        specs.stages = stages;
                        specs.name = base;
                        specs.titlesprefix = [n1 ' -- ' n2 ' ' base];
                        v = VisHelpers(specs);
                        collected.(key) = v.plot_global(false);
                    end
                end
            end
            if strcmp(action,'flat_averages')
                warning('off','MATLAB:xlswrite:AddSheet');
                savefile = fullfile(self.datafolder,['restep-' base '-gflats.xlsx']);
                group_keys = fieldnames(collected)';
                if exist(savefile,'file')
                    delete(savefile);
                end
                for s=please_process
                    current_excel_row  = 1;
                    writestage = false;
                    for k = group_keys
                        if any(strcmp(fieldnames(collected.(k{:})),s{:}))
                            writestage = true;
                        end
                    end
                    if ~writestage
                        continue;
                    end
                    xlswrite(savefile,self.data_names,s{:},'B1');
                    for k = group_keys
                        if any(strcmp(fieldnames(collected.(k{:})),s{:}))
                            current_excel_row = current_excel_row + 1;
                            xlswrite(savefile,cellstr(k),s{:},['A' num2str(current_excel_row)]);
                            xlswrite(savefile,collected.(k{:}).(s{:}),s{:},['B' num2str(current_excel_row)]);
                            
                        end
                    end
                end
                syshelpers.remove_default_sheets(savefile);
            end
        end
        
        function d = subject_data(self,gistfile,stage,base)
            %SUBJECT_DATA just return relevant data from a subject's saved
            % gist file
            d = [];
            load(gistfile);  %#ok<LOAD> "gist"
            if isempty(gist.learning) || ~any(strcmp(fieldnames(gist.learning),stage))
                return;
            end
            srcrow = gist.learning.(stage).(base);
            d = srcrow(1,ismember(gist.learning_keys,self.data_names)).Variables;
            clear gist;
        end
    end
end

