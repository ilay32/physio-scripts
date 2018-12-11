%GROUPANALYSIS wrapper script for group analysis
%   gathers available steps data and plots group-averaged symmetries
clear; clc; close all;
addpath 'matclasses'


% get parent directory from user
subjects_dir = uigetdir('Parent Directory for Saved Steps Data of Subjects (.mat)');
%subjects_dir = 'Q:\testdata\adi-examples\saved-steps';
if subjects_dir == 0
    error('Aborting');
end
%cleanstagenames = cellfun(@matlab.lang.makeValidName,QualySubject.stagenames,'UniformOutput',false);
% get experiment part to process 
%phase = listdlg('ListString',QualySubject.partnames,'PromptString',...
%    'Select Session to Analyze','SelectionMode','single');
%assert(~isempty(phase),'no session selected');

% look for appropriate files of identified and measured steps
for phase=1:3
    partstr = ['part' num2str(phase)];
    datfiles = dir(fullfile(subjects_dir,['*' partstr '_steplengths.mat']));
    if isempty(datfiles)
        warning('there are no files in this folder that look like "<ID>_%s_steplengths.mat"\nskipping this part.',partstr);
    end
    numsubjects = length(datfiles);
    subjids = cellfun(@(c)extractBefore(c,'_'),extractfield(datfiles,'name'),'UniformOutput',false);

    % polulate a cell array of step data, row per subject column per stage 
    steps = cell(numsubjects,QualySubject.numstages);
    for subj=1:numsubjects
        % this is a cell array with 2-column matrices in each cell
        dat =  load(fullfile(datfiles(subj).folder,datfiles(subj).name));
        for s = 1:length(dat.stagedat)
            steps{subj,s} = dat.stagedat(s).step_lengths;
        end
    end
    
    assert(size(steps,2) == QualySubject.numstages,'somthing''s wrong. stages missing');
    numstages = QualySubject.numstages;
    % loop the cell array by stage (column) and get mean symmetries
    % as much as the subject with the least steps allows
    % also collect the baseline means for future normalization
    grouped_syms = cell(1,numstages);
    vtps = cell(1,numstages);
    [vtps{:}] = deal('double');
%     stagemeans = table('Size',[numsubjects,numstages],...
%         'VariableTypes',vtps,...
%         'RowNames',subjids,...
%         'VariableNames',cleanstagenames...
%     );
    subject_normalizers = nan*ones(numsubjects);
    for stage = 1:numstages
        [how,long] = min(cellfun(@length,steps(:,stage)));
        stagesyms = zeros(how,numsubjects);
        for subj=1:numsubjects
            stagesteps = steps{subj,stage};
            syms = VisHelpers.symmetries(...
                stagesteps(1:how,1),...
                stagesteps(1:how,2),...
                QualySubject.remove_outliers...
            );
            stagesyms(:,subj) = syms;
            %stagemeans(subjids{subj},cleanstagenames).Variables = mean(syms);
            if stage==3 % using last 0.5 m/s part to normalize
                subject_normalizers(subj) = abs(mean(syms(end-min(30,length(syms)-1):end)));
            end
        end
        grouped_syms{stage} = stagesyms;
    end
    
    % loop the grouped symmetries to normalize by every subject's baseline mean
    for s=1:numstages
        for j=1:numsubjects
            raw_symmetries = grouped_syms{s}(:,j);      
            %normalizer = mean(stagemeans(subjids{j},1:3).Variables);
            grouped_syms{s}(:,j) =  raw_symmetries/abs(subject_normalizers(j));
        end
    end
    
    % construct the stages object for Visualizer
    specs = struct;
    specs.name = QualySubject.symmetry_base;
    specs.bastian_limits = QualySubject.bastian_limits;
    specs.direction_strategy = QualySubject.direction_strategy;
    specs.remove_outliers = false;
    specs.model = QualySubject.model;
    specs.titlesprefix = ['Group Analysis (' subjects_dir ') ' QualySubject.partnames{phase}];
    stages = VisHelpers.initialize_stages(numstages);
    % loop the collected symmetries to construct the stages struct for
    % VisHelpers (similar to compile_stages in QualySubject)
    for s = 1:numstages
        d = mean(grouped_syms{s},2);
        stages(s).data = d/abs(max(d));
        stages(s).name = QualySubject.stagenames{s};
        if s <= 3
            stages(s).include_inbaseline = true;
        else
            stages(s).perturbation_magnitude = 2;
            stages(s).fit_curve = true;  
            if s==4
                stages(s).expected_sign = -1;
            else
                stages(s).expected_sign = 1;
            end
        end
    end
    specs.stages = stages;
    visu = VisHelpers(specs);
    ltimes = visu.plot_global(false);
    lnames = fieldnames(ltimes);
    for i=1:length(lnames)
        fprintf('%s learning times summary (model: %s):\n',lnames{i},QualySubject.model)
        disp(ltimes.(lnames{i}));
        fprintf('params:\n');
        disp(ltimes.(lnames{i}).params);
    end
end
        
        
        
        
        
        
        
