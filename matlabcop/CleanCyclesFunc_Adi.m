function [HSIndx] = CleanCyclesFunc_Adi(FP1,WalkRunTh,RemoveManual,Slope)
% This function identify heelstrike from the force data, using RLA
% trajectory, and removing noisy gait cycles, where force was applied on both plates
% FP1 - the FP of interest (RFP for positive slopes, LFP for negative slopes.
% RLA - Right Heel Trajectory.
% WalkRunTh - MINPEAKDISTANCE th for findpeaks command.
% Walk = 100, Run = 60

% 9/6/15 Update - Ignoring first peak
% 23/10/17 - Set different th for walking and running, based on WalkRunTh
% 24/10/17 - Deal with more noise options

global Mass;

if WalkRunTh == 60
    th = Mass*9.8*1.5; % Threshold = Body weight*1.5
elseif WalkRunTh >= 100
    th = Mass*9.8; % Threshold = Body weight
end

[Pks, Pks_ind] = findpeaks(FP1,'MINPEAKDISTANCE', WalkRunTh*0.8); %, 'MINPEAKHEIGHT', -MRLA);
% figure; plot(FP1)
% hold on; plot(Pks_ind, Pks, '*r')


MCycle = mean(diff(Pks_ind)); %mean cycle length

% Find heelstrike (HS) and TOIndx (TO)
HSDiff = [1; 1; diff(FP1)];
HSDiff(end) = []; %Remove last value
%Find the begining of each gait cycle using heel strike
HSLogicVec = (FP1 > 0) + (HSDiff == 0); %This vector is a sum of 2 logical vector: RFP>0 & MovedDiff==0
TODiff = diff(FP1); TODiff = [TODiff(2:end); 1; 1];
TOLogicVec = (FP1 > 0) + (TODiff == 0); %This vector is a sum of 2 logical vector: RFP>0 & MovedDiff==0

for i=2:length(Pks)-1

    HStemp = find(HSLogicVec(Pks_ind(i-1):Pks_ind(i)) == 2,1,'last')+Pks_ind(i-1)-1;
    if HStemp
        HSIndx(i-1) = HStemp;
    else
        HSIndx(i-1) = 0;
    end
    TOtemp = find(TOLogicVec(Pks_ind(i):Pks_ind(i+1)) == 2,1,'first')+Pks_ind(i)-1;
    if TOtemp
        TOIndx(i-1) = TOtemp;
    else
        TOIndx(i-1) = 0;
    end
end

% Remove zero values
HSIndx((HSIndx==0)) = [];
TOIndx((TOIndx==0)) = [];

HSIndx = HSIndx-1;
TOIndx = TOIndx+1;
clear TOLogicVec HSLogicVec TODiff HSDiff

if TOIndx(1) < HSIndx(1) % start with heelstrike
    TOIndx(1) = [];
end


figure; plot(FP1);
hold on; plot(HSIndx,0,'r*');
hold on; plot(TOIndx,0,'g*');
legend('Force data', 'Heel strike')

Len = length(HSIndx);
HSIndx = HSIndx';
HSIndx(:,2) = ones(Len,1);

% Identify faulty cycles
for i = 1:Len-1
%     if max(FP1(TOIndx(i):HSIndx(i+1),3)) > 20 % Noisy cycle
%         HSIndx(i,2) = 0;
%     end
    if max(FP1(HSIndx(i):TOIndx(i))) < th % Force applied on the other FP
        HSIndx(i,2) = 0;
    end
    if HSIndx(i+1) - TOIndx(i) < 20 % Swing phase is too short
        HSIndx(i,2) = 0;
    end
    if TOIndx(i) - HSIndx(i) > WalkRunTh*1.2 % No swing at all - stance is longer than whole cycle
        HSIndx(i,2) = 0;
    end
end

if RemoveManual
    HSIndx(RemoveManual,2) = 0;
end

if sum(HSIndx(:,2)==0)
    hold on; plot(HSIndx(HSIndx(:,2)==0,1),0,'ko');
end
title(['Heel strike and toe-off, at slope ' Slope '%'])
