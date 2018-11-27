%GROUPANALYSIS wrapper script for group analysis
%   gathers available steps data and plots group-averaged symmetries
clear; clc; close all;
addpath 'matclasses'


% get parent directory from user
subjects_dir = uigetdir('Parent Directory for Saved Steps Data of Subjects (.mat)');
if subjects_dir == 0
    error('Aborting');
end

% get experiment part to process 
%phase = listdlg('ListString',QualySubject.partnames,'PromptString',...
%    'Select Session to Analyze','SelectionMode','single');
%assert(~isempty(phase),'no session selected');

% look for appropriate files of identified and measured steps
for phase=1:3
    partstr = ['part' num2str(phase)];
    datfiles = dir(fullfile(subjects_dir,['*' partstr '_steplengths.mat']));
    assert(~isempty(datfiles),'there are no files in this folder that look like "%s_steplengths.mat"',partstr);
    numsubjects = length(datfiles);


    % polulate a cell array of step data, row per subject column per stage 
    steps = cell(numsubjects,QualySubject.numstages);
    for subj=1:numsubjects
        % this is a cell array with 2-column matrices in each cell
        dat =  load(fullfile(datfiles(subj).folder,datfiles(subj).name));
        for s = 1:length(dat.stagedat)
            steps{subj,s} = dat.stagedat(s).step_lengths;
        end
    end

    % loop the cell array by stage (column) and get mean symmetries
    % as much as the subject with the least steps allows

    syms = cell(1,QualySubject.numstages);
    for stage = 1:size(steps,2)
        [how,long] = min(cellfun(@length,steps(:,stage)));
        syms{stage} = [];
        for subj=1:numsubjects
            stagesteps = steps{subj,stage};
            normalize = stage >= 4;
            syms{stage} = [syms{stage},...
                VisHelpers.symmetries(...
                    stagesteps(1:how,1),...
                    stagesteps(1:how,2),...
                    QualySubject.faster_side,...
                    QualySubject.remove_outliers,...
                    normalize...
                )];
        end
    end

    % construct the stages object for Visualizer
    specs = struct;
    specs.name = QualySubject.symmetry_base;
    specs.remove_outliers = false;
    specs.model = QualySubject.model;
    specs.titlesprefix = ['Group Analysis (' subjects_dir ') ' QualySubject.partnames{phase}];
    stages = VisHelpers.initialize_stages(QualySubject.numstages);
    for s = 1:QualySubject.numstages
        % this repeats QualySubject::compile_stages more or less
        stages(s).data = mean(syms{s},2);
        stages(s).name = QualySubject.stagenames{s};
        if s <= 3
            stages(s).include_inbaseline = true;
        else
            stages(s).faster = QualySubject.faster_side;
            stages(s).fit_curve = true;
            stages(s).normalize = true;   
            if s==4
                stages(s).speeds = struct('left',0.5,'right',1);
            else
                stages(s).speeds = struct('left',1,'right',0.5);
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
        
        
        
        
        
        
        
        
