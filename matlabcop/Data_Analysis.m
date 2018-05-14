% This Programs Analyses 2-plate COP Data
% First, it (optionally) prompts the user to mark the walking session
% stages
% With the stages, it finds step lengths and computes step symmetry
% accordingly
clear; clc;
    
% choose *.mat file - experiment results and load it
[log_file, log_path] = uigetfile('C:\Users\soferil\misc-data\*.mat', 'Select data file');
if log_file == 0, error('No log file specified'); end
absdfile = fullfile(log_path,log_file);
load(absdfile);
part = regexp(log_file,'part\d{1}','match');

% define some globals
stagenames = {'first 0.5 m/s','1.0 m/s', 'second 0.5 m/s', 'adaptation','post adaptation'};
split_prompts = {
    'Set walking initiation',...
    'Set switching from 0.5 m/s to 1 m/s',...
    'Set switching from 1 m/s to 0.5 m/s',...
    'Set the end 0.5 m/s baseline',...
    'Set begining of adaptation',...
    'Set the end of adaptation',...
    'Set the begining of post-adaptation',...
    'Set the end of post-adaptation'
};
durations = [10,17,17,17,17,115,20]*1000;
numsplits = length(split_prompts);
numstages = length(stagenames);


FP_z(:,1) = R_FP{1}(:,3); % Right
FP_z(:,2) = L_FP{1}(:,3); % Left

global frate;
frate = FRAME_RATE{1,1};
steps = cell(numstages,2);
rlinds = zeros(2,numsplits);

% for each plate, load stage limits from file or get them from user
for side = 1:2
    % prepare the indices file either for reading or writing depending on
    % chosen action
    suff = 'right';
    if side == 2 suff = 'left'; end
    [p,base,ext] = fileparts(absdfile);
    absindfile = fullfile(p,[base '-' suff '-inidices.mat']);
    
    % user decides whether to load indices from file or mark them in figures
    action = 0;
    while action ~= 1 & action ~= 2
        action = input([suff ': Enter 1 for manual marking of stages,  2 for loading a saved list: ']);
    end
    
    if action == 2
        % will load inidices as [ R L ] x [ 8 stages ] matrix if exists under
        % in same directory as the current data file + '-indices'
        load(absindfile);
        rlinds(side,:) = ix_final;
    else
        ix = zeros(1,numsplits);
        Force = FP_z(:,side);
        % plot approximate stages and ask user for marks
        for split=1:numsplits
            figure('units','normalized','outerposition',[0 0 1 1]);
            from = sum(ix) + 1;
            if split <= length(durations) 
                to = from + durations(split); 
            else
                to = size(Force,1); 
            end
            plot(Force(from:to));
            title([split_prompts{split} ' ' suff]);
            xlabel('minutes');
            [t,l] = minutes(1:(to - from));
            xticks(t);
            xticklabels(l);
            [x,~] = ginput(1); % get user decision
            ix(split) = round(x);
            close;
        end
        % plot the whole thing and offer to save to disk
        ix_final = cumsum(ix);
        rlinds(side,:) = ix_final;
        figure('units','normalized','outerposition',[0 0 1 1]);
        plot(Force);
        hold on;
        plot(ix_final,600*ones(1,8), '*r');
        saveit = input('Enter 1 to save the marked times: ');
        if saveit == 1
            save(absindfile,'ix_final');
        end
    end
end

% find HS/TO timings directly from COP within each stage
for side = 1:2
    Force = FP_z(:,side);
    COP = R_COP;
    if side == 2
        COP = L_COP;
    end
    stage = 1;
    for split = 1:size(rlinds,2)
        if (split > 1 & split < 5) | mod(split,2) == 0
            s = rlinds(side,split-1);
            e = rlinds(side,split);
            steps{stage,side} = StepTimes(s,e,COP{1,1}(:,1),Force);
            stage = stage + 1;
        end
    end
end

% plot length symmetry of aligned steps of every stage
plotseparate = input('plot the step lenghts and symmetries per-stage? Enter 1 to plot ');
glob = zeros(0,2);
for stage=1:numstages
    fprintf('\nentering %s',stagenames{stage});
    paired  = AlignSteps(steps(stage,:),R_COP{1,1},L_COP{1,1},1);
    numsteps = size(paired,1);
    fprintf('\nfound %d matching steps out of %d left and %d right\n',numsteps,size(steps{stage,2},1),size(steps{stage,1},1));
    globsteps = 1;
    glob = [glob;paired];
    if plotseparate
        plotsteps(paired,part{1},stagenames{stage});
    end 
end
fprintf('\n');
plotsteps(glob,part{1});

function [ticks,labels] = minutes(sequence)
    global frate;
    ticks = 0:30*frate:length(sequence);
    labels = (0:1:numel(ticks))/2;
end

function  plotsteps(paired_steps,prepost,toptitle)
    figure('name',['step lengths and symmetry ' prepost]);
    subplot(2,1,1);
    
    x = (1:length(paired_steps));
    y = ((paired_steps(:,1) - paired_steps(:,2)) ./ (paired_steps(:,1) + paired_steps(:,2)))';
    symsd = std(y);
    
    fill([x,fliplr(x)],[y + symsd,fliplr(y - symsd)],[0.75,0.75,0.75],'LineStyle','none');
    hold on;
    if nargin == 3
        title(toptitle);
    else
        title(prepost);
    end
  
    plot(x,mean(y)*ones(1,size(x,2)));
    plot(x,y);
    ylabel('steplength symmetry');
    ylim([-1,1]);
    legend('1 SD','mean','symmetry');
    hold off;
    
    subplot(2,1,2);
    scatter(1:size(paired_steps,1),paired_steps(:,1),'filled');
    ylabel('length');
    ylim([0,1]);
    hold on;
    scatter(1:size(paired_steps,1),paired_steps(:,2),'filled');
    legend({'right','left'});
    xlabel('step no.');
    hold off;
end
% [sfile,spath] = uiputfile('*.mat','Save the Step Length Symetry Data');
% if sfile
%     save(fullfile(spath,sfile),Symm);
% end
