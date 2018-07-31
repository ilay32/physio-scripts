%SUBJECTANALYSIS wrapper script for analyzing step length data
%   First, it (optionally) prompts the user to mark the walking stages
%   With the stages, it finds step lengths and computes step symmetry
%   accordingly
clear; clc; close all;
addpath '..\matclasses';
% choose *.mat file - experiment results and load it
% !! the .mat file must be the output of a Visual3D pipeline created by Anat Shkedy that
% runs on the Qualisys .c3d export of the data !!
[log_file, log_path] = uigetfile('*.mat', 'Select data file');
if log_file == 0, error('No log file specified'); end
absdfile = fullfile(log_path,log_file);
load(absdfile);
[~,toks] = regexp(log_file,'(\w+)_part(\d)','match','tokens');
assert(all(size(toks) == [1,1]),'the .mat file doesn''t match  the expected name format:\nID_part<no.>.mat');
part = str2double(toks{1,1}{2});
subject_id = toks{1,1}{1};

% define some globals
partnames = {'before excercise','after exercise','after 1 week'};
stagenames = {'first 0.5 m/s','1.0 m/s', 'second 0.5 m/s', 'adaptation','post adaptation'};
split_prompts = {
    'Mark the boundaries of the first three stages',...
    'Mark the boundaries of the adaptation stage',...
    'Mark the boundaries of the post adaptation stage'...
};
split_durations  = [360,900,300]; % expected durations of stages in seconds
numsplits = 8;
numstages = length(stagenames);


FP_z(:,1) = R_FP{1}(:,3); % Right
FP_z(:,2) = L_FP{1}(:,3); % Left


frate = FRAME_RATE{1,1};
steps = cell(numstages,2);


% load stage limits from file or get them from user
% one side is enough since the stage timings are uniform for both plates.
% the decision to use column 2 of the force data, is completely arbitrary.

[p,base,~] = fileparts(absdfile);
absindfile = fullfile(p,[base '-boundaries.mat']);

% user decides whether to load indices from file, if found, or mark them in figures
action = 0;
if exist(absindfile,'file')
    while action ~= 1 && action ~= 2
        action = input('Enter 1 for manual marking of stages, 2 for loading a saved list: ');
    end
end    
if action == 2
    % will load inidices as [ R L ] x [ 8 stages ] matrix if exists under
    % in same directory as the current data file + '-indices'
    tmp = load(absindfile);
    boundaries = tmp.boundaries;
    clear tmp;
else
    stage_margin = 30*frate; % 1/2 minute before and after expected start
    ix = zeros(1,numsplits);

    % plot approximate stages and ask user for marks
    for prompt=1:length(split_durations)
        [latest_point,latest_index] = max(ix);
        if latest_point == 0
            latest_index = 0;
        end
        figure('units','normalized','outerposition',[0 0 1 1]);
        from = max(1,latest_point  - stage_margin);
        to = min(from + (split_durations(prompt)*frate) + stage_margin*2,length(FP_z)); 
        plot(FP_z(from:to,2));
        title(split_prompts{prompt});
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
    boundaries = ix;
end

% show the user the overall segmentation on both sidesfor side=1:2
for side=1:2
    sidename = 'right';
    if side == 2
        sidename = 'left';
    end
    Force = FP_z(:,side);
    figure;
    plot(Force);
    title(['Current Boundaries on Fz ' sidename]);
    hold on;
    for i=1:length(boundaries)
        b = boundaries(i);
        line([b,b],get(gca,'YLim'),'color','black','LineWidth',2,'Linestyle', '--');
    end
    hold off;
end

% if new (action is not 2) prompt for save
if action ~= 2
    saveit = input('save the marked stage boundaries [y/n]? ', 's');
    if strcmp(saveit,'y')
        save(absindfile,'boundaries');
    end
end

% I put this here to make sure that the user looks at the plotted
% boundaries even in the load from file case
proceed = input('close boundaries graphs and proceed [y/n]? ','s');
if ~strcmp('y',proceed)
    error('operation aborted');
else
    close all;
end

% find HS/TO times directly from COP within each stage
for side = 1:2
    fz = FP_z(:,side);
    COP = R_COP;
    if side == 2
        COP = L_COP;
    end
    stage = 1;
    for boundary = 1:size(boundaries,2)
        % since the first three stages are back to back, while the last
        % two have a break before them, the stages are 1-2,2-3,3-4,5-6,7-8
        % this if statement catches 2,3,4,6 and 8
        if (boundary > 1 && boundary < 5) || mod(boundary,2) == 0
            s = boundaries(boundary-1);
            e = boundaries(boundary);
            steps{stage,side} = StepTimes(s,e,COP{1,1}(:,1),fz);
            stage = stage + 1;
        end
    end
end

% collect aligned steps to cell array of matrices
stagedat = cell(1,numstages);
for stage=1:numstages
    fprintf('\nentering %s',stagenames{stage});
    paired  = AlignSteps(steps(stage,:),R_COP{1,1},L_COP{1,1},1);
    numsteps = size(paired,1);
    fprintf('\nfound %d matching steps out of %d left and %d right\n',numsteps,size(steps{stage,2},1),size(steps{stage,1},1));
    globsteps = 1;
    stagedat{stage} = paired;
end

% make specs for the visualizer
specs = struct;
specs.name = 'step length';
specs.data = stagedat;
specs.stagenames = stagenames;
specs.titlesprefix = [subject_id ' ' partnames{part}];
specs.baselines = 1:3;
specs.model = 'exp2';
specs.fitmodel = 4:5;
visu = VisHelpers(specs);

plotseparate = input('\n\nplot per-stage graphs [y/n]? ','s');
if strcmp(plotseparate,'y')
    for s=1:numstages
        visu.plot_symmetries(s);
    end
end
visu.plot_global(true);

sfilename = [subject_id '_part' num2str(part) '_stepsdata.mat'];
[sfile,spath] = uiputfile(sfilename,'Save the Step Length Data');
if sfile
    save(fullfile(spath,sfile),'stagedat');
end
