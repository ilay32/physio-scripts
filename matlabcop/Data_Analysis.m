
%Data analysis - extract heel strike
clear; close all; clc;

    
% choose *.mat file - experiment results and load it
[log_file, log_path] = uigetfile('C:\Users\soferil\misc-data\*.mat', 'Select data file');
if log_file == 0, error('No log file specified'); end
absdfile = fullfile(log_path,log_file);
load(absdfile);

% define some globals
titles = {
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
numsplits = length(titles);
numstages = numsplits/2 + 1;


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
        ix = zeros(numsplits);
        Force = FP_z(:,side);
        % plot approximate stages and ask user for marks
        for split=1:length(titles)
            figure('units','normalized','outerposition',[0 0 1 1]);
            from = sum(ix) + 1;
            if split <= length(durations) 
                to = from + durations(split); 
            else
                to = size(Force,1); 
            end
            plot(Force(from:to));
            title([titles{split} suff]);
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

% find step lengths directly from COP within each stage
for side = 1:2
    COP = R_COP;
    if side == 2
        COP = L_COP;
    end
    stage = 1;
    for split = 1:size(rlinds,2)
        if (split > 1 & split < 5) | mod(split,2) == 0
            s = rlinds(side,split-1);
            e = rlinds(side,split);
            steps{stage,side} = StepLengths(s,e,COP{1,1}(:,1));
            stage = stage + 1;
        end
    end
end

function [ticks,labels] = minutes(sequence)
    global frate;
    ticks = 0:30*frate:length(sequence);
    labels = (0:1:numel(ticks))/2;
end

% [sfile,spath] = uiputfile('*.mat','Save the Step Length Symetry Data');
% if sfile
%     save(fullfile(spath,sfile),Symm);
% end
