%Data analysis - extract heel strike
clear; close all; clc;

% choose *.mat file - experinebt results
[log_file, log_path] = uigetfile('*.mat', 'Select data file');
if log_file == 0, error('No log file specified'); end

load(fullfile(log_path,log_file));

FP_z(:,1) = R_FP{1}(:,3); % Right
FP_z(:,2) = L_FP{1}(:,3); % Left

for i = 1:2 % Right and left
ix = [];

Force = FP_z(:,i);    
% Segement data - different walkng velocities
figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force(1:10000));
title('Set walking initiation')
[x,~] = ginput(1); % Walking initiation
ix(1) = round(x);

figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force(ix(1):ix(1) + 17000));
title('Set switching from 0.5 m/s to 1 m/s ')
[x,~] = ginput(1); % Switch from 0.5 m/s to 1 m/s 
ix(2) = round(x);

figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force(sum(ix):sum(ix) + 17000));
title('Set switching from 1 m/s to 0.5 m/s')
[x,~] = ginput(1); % Switch from 1 m/s to 0.5 m/s 
ix(3) = round(x);

figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force(sum(ix):sum(ix) + 17000));
title('Set the end 0.5 m/s baseline')
[x,~] = ginput(1); % finish 0.5 m/s baseline
ix(4) = round(x);


figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force(sum(ix):sum(ix) + 17000));
title('Set begining of adaptation')
[x,~] = ginput(1); % Start adaptation
ix(5) = round(x);

figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force(sum(ix) + 80000:sum(ix) + 115000));
title('Set the end of adaptation')
[x,~] = ginput(1); % Finish adaptation
ix(6) = round(x) + 80000;

figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force(sum(ix) - 10000:sum(ix) + 20000));
title('Set the begining of post-adaptation')
[x,~] = ginput(1); % Finish adaptation
ix(7) = round(x) - 10000;

figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force(sum(ix):end));
title('Set the end of post-adaptation')
[x,~] = ginput(1); % Finish adaptation
ix(8) = round(x);

ix_final = cumsum(ix);
figure('units','normalized','outerposition',[0 0 1 1]);
plot(Force);
hold on;
plot(ix_final,600*ones(1,8), '*r')

% load('ix_final_part1')

% Heel strikes for first 0.5 m/s baseline
[HSIndx{1,i}] = CleanCyclesFunc_Adi(Force(ix_final(1):ix_final(2)),150,0,0);

% Heel strikes for 1 m/s baseline
[HSIndx{2,i}] = CleanCyclesFunc_Adi(Force(ix_final(2):ix_final(3)),100,0,0);

% Heel strikes for first 0.5 m/s baseline
[HSIndx{3,i}] = CleanCyclesFunc_Adi(Force(ix_final(3):ix_final(4)),150,0,0);

% Heel strikes for split belt adaptation
[HSIndx{4,i}] = CleanCyclesFunc_Adi(Force(ix_final(5):ix_final(6)),120,0,0);

% Heel strikes for post- adaptation
[HSIndx{5,i}] = CleanCyclesFunc_Adi(Force(ix_final(7):ix_final(8)),150,0,0);

end

