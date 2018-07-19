%GROUPANALYSIS wrapper script for group analysis
%   gathers available steps data and plots group-averaged symmetries


clear; clc;

% repeat some globals from the subject analysis script
partnames = {'before excercise','after exercise','after 1 week'};
stagenames = {'first 0.5 m/s','1.0 m/s', 'second 0.5 m/s', 'adaptation','post adaptation'};
numstages  = length(stagenames);


% get parent directory from user
subjects_dir = uigetdir('Parent Directory for Saved Steps Data of Subjects (.mat)');
if subjects_dir == 0
    error('Aborting');
end

% get experiment part to process 
phase = listdlg('ListString',partnames,'PromptString',...
    'Select Session to Analyze','SelectionMode','single');
assert(~isempty(phase),'no session selected');



% look for appropriate files of identified and measured steps
partstr = ['part' num2str(phase)];
datfiles = dir(fullfile(subjects_dir,['*' partstr '_stepsdata.mat']));
assert(~isempty(datfiles),'there are no files in this folder that look like "%s_stepsdata.mat"',partstr);
numsubjects = length(datfiles);

% polulate a cell array of step data, row per subject column per stage 
steps = cell(numsubjects,numstages);
for subj=1:numsubjects
    % this is a cell array with 2-column matrices in each cell
    dat =  load(fullfile(datfiles(subj).folder,datfiles(subj).name));
    for s = 1:length(dat.stagedat)
        steps{subj,s} = dat.stagedat{s};
    end
end

% loop the cell array by stage (column) and get mean symmetries
% as much as the subject with the least steps allows
syms = cell(1,numstages);
for stage = 1:size(steps,2)
    [how,short] = min(cellfun(@length,steps(:,stage)));
    syms{stage} = [];
    for subj=1:numsubjects
        stagesteps = steps{subj,stage};
        syms{stage} = [syms{stage},VisHelpers.symmetries(stagesteps(1:how,:))];
    end
end
specs = struct; 
specs.name = 'step length';
specs.data = cellfun(@(s)mean(s,2),syms,'UniformOutput',false);
specs.stagenames = stagenames;
specs.titlesprefix = '';
specs.baselines = 1:3;
specs.model = 'exp2';
specs.fitmodel = 4:5;

visu = VisHelpers(specs);
visu.plot_global();
        
        
        
        
        
        
        
        
        
        