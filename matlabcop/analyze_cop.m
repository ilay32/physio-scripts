% analyze one file of COP data

clear all
transition = 0;%input('Number of samples on either side of Critcial/Transition Point to eliminate from regression?');
lt_end_sec = 10;
[file path] = uigetfile({'*.dat'; '*.csv'}, ['select cop file']); % This default directory can be changed for convenience

disp(['Processing ' file ' . . .']);
[p n e] = fileparts(file);
status  = mkdir([path n]);
if status
    savepath = [path n '\'];
else
    savepath = path;
end;
if e == '.dat'
    [data,forces,sample_rate] = bioware_read3([path file],0); % No filtering, forces not used here
    copx(:,1) = data(:,1);
    copy(:,1) = data(:,2);    
%treadmill data
elseif ~strcmp(e,'.csv')
    disp('wrong file given');
    exit;
else
    data = csvread([path file],2);
    data(any(isnan(data),2),:) = [];
    copx(:,1) = data(:,3);
    copy(:,1) = data(:,4);
    time(:,1) = data(:,1);
    % in this case we can compute the sample rate Hz like so:
    sample_rate = double(int16(1 / (time(2,1) - time(1,1))));
    disp(['sample rate: ' num2str(sample_rate)]);
end
lt_end = lt_end_sec*sample_rate; % Convert from seconds to # of samples

[rows,cols] = size(copx);
SEC=floor(rows/sample_rate);

% trim last second 
copx = copx(end-SEC*sample_rate+1:end,:); % Take last 30s after discarding 1 second from end
copy = copy(end-SEC*sample_rate+1:end,:);

% trim first 3 seconds
copx = copx(3*sample_rate+1:end,:);
copy = copy(3*sample_rate+1:end,:);

% get the length...
length = size(copx, 1)/sample_rate;

% Eliminate any trials with Nans (indicating unrealistically large COP values)
temp = [copx; copy];
bad = find(any(isnan(temp)));
if ~isempty(bad),
   disp(['Trial number(s) ' num2str(bad) ' rejected due to unrealistic COP values']);
   copx(:,bad)=[];
   copy(:,bad)=[];
end;

%Calculate ensemble SD function
% Yaron 17/7 added 'length' as parameter for stabilogram_diffusion...
[sdfx]=stabilogram_diffusion(copx,sample_rate,length ,2,0); 
[sdfy]=stabilogram_diffusion(copy,sample_rate,length ,2,0);
sdf(:,1) = (1/sample_rate:1/sample_rate:length -(1/sample_rate))';
sdf(:,2) = sdfx(:,2);
sdf(:,3) = sdfy(:,2);
sdf(:,4) = sdf(:,2) + sdf(:,3);

% Calculate SDF Parameters for the ensemble average SDF
% Coeffs format
%			   1        2       3        4   5      6
%        95%Conf   Param   95%Conf   R^2  p  Intercept
%  1 Dxs
%  2 Dys
%  3 Drs
%  4 Dxl
%  5 Dyl
%  6 Drl
%  7 Hxs
%  8 Hys
%  9 Hrs
% 10 Hxl
% 11 Hyl
% 12 Hrl

% CP Format
%    CP by loglog slope  CP by intersection
% 1 Ctx
% 2 Cty
% 3 Ctr
% 4 Cdx
% 5 Cdy
% 6 Cdr

[coeffs, cp, long_term_end] = sdf_parameters3(sdfx(:,1),sdf(:,2:3),0,transition,lt_end); %No checking of r^2, 200ms transition region. Long_term_end is a 1x3 vector
disp('. . . SDF parameters calculated . . .');
save([savepath 'sdfcoeffs.txt'],'coeffs','-ascii','-tabs'); % [95%Conf Param  95%Conf R^2 p Intercept]
save([savepath 'cp.txt'],'cp','-ascii','-tabs');			   % [CP by loglog slope  CP by intersection]
save([savepath 'sdf.txt'],'sdf','-ascii','-tabs');
disp(' . . .& saved');
   
% Calculate traditional parameters
% 1  Average of mean COP from each trial X
% 2  Average of mean COP from each trial Y
% 3  Standard Deviation of trial means  X 
% 4  Standard Deviation of trial means  Y
% 5  Average of COP range from each trial X 
% 6  Average of COP range from each trial Y
% 7  Average Median Power Frequency X 
% 8  Average Median Power Frequency Y 
% 9  Average of trial Mean velocities X 
% 10 Average of trial Mean velocities Y
% 11 Average of trial Mean velocities R
% 12 Average Sway Area per second- area enclosed by COP R
[output]= copparam(copx,copy,sample_rate,15);  % Low-pass filter data at 15Hz, calculate traditional parameters
save([savepath 'copmeas.txt'],'output','-ascii','-tabs');
disp('COP measures calculated & saved');
   
    
% Plot SDF Functions with Slopes
warning off
trans_seconds = transition/100; % Size of linear transition region in seconds, based upon 100Hz data

figure('Name',[path ' Linear'],...
'PaperOrientation','landscape',...
'PaperPosition',[.25 .25 10.5 8]);
subplot(3,1,1)
hold on
plot(sdf(:,1),sdf(:,2),'r')
plot(.01:.01:cp(1,1)-trans_seconds,((.01:.01:cp(1,1)-trans_seconds)*2*coeffs(1,2)+ coeffs(1,6)),'m:');  % Dxs
plot(cp(1,1):.01:long_term_end(1)/100, ((cp(1,1):.01:long_term_end(1)/100) *2*coeffs(4,2)+ coeffs(4,6)),'m:');  % Dxl
 title([path ': SDF Linear']);
 text(10,10,['R^2 ' num2str(coeffs(1,4)) ',  ' num2str(coeffs(4,4))]);
 ylabel('MSD ML (mm^2)');
 set(gca,'XTick',0:1:SEC);

subplot(3,1,2)
hold on
plot(sdf(:,1),sdf(:,3),'g')
plot(.01:.01:cp(2,1)-trans_seconds,((.01:.01:cp(2,1)-trans_seconds)*2*coeffs(2,2)+ coeffs(2,6)),'m:');  % Dys
plot(cp(2,1):.01:long_term_end(2)/100, ((cp(2,1):.01:long_term_end(2)/100) *2*coeffs(5,2)+ coeffs(5,6)),'m:');  % Dyl
text(10,10,['R^2 ' num2str(coeffs(2,4)) ',  ' num2str(coeffs(5,4))]);
ylabel('MSD AP (mm^2)');
set(gca,'XTick',0:1:SEC);

subplot(3,1,3)
hold on
plot(sdf(:,1),sdf(:,4),'b')
plot(.01:.01:cp(3,1)-trans_seconds,((.01:.01:cp(3,1)-trans_seconds)*2*coeffs(3,2)+ coeffs(3,6)),'m:');  % Drs
plot(cp(3,1):.01:long_term_end(3)/100, ((cp(3,1):.01:long_term_end(3)/100) *2*coeffs(6,2)+ coeffs(6,6)),'m:');  % Drl
text(10,10,['R^2 ' num2str(coeffs(3,4)) ',  ' num2str(coeffs(6,4))]);
xlabel('Time Interval (s)');
ylabel('MSD R (mm^2)');
set(gca,'XTick',0:1:SEC);

saveas(gcf,[savepath 'sdflin.fig'])

figure('Name',[path ' LogLog'],...
'PaperOrientation','landscape',...
'PaperPosition',[.25 .25 10.5 8]);
lsdf = log10(sdf);
ct(1:3,1) = cp(1:3,1)*100; % Sample of time vector corresponding to Ct

subplot(3,1,1)
hold on
plot(lsdf(:,1),lsdf(:,2),'r')
plot(lsdf(1:ct(1,1)-transition,1),    (lsdf(1:ct(1,1)-transition,1)   *2*coeffs(7,2) + coeffs(7,6))  ,'m:');  % Hxs
plot(lsdf(ct(1,1)+transition:long_term_end(1),1), (lsdf(ct(1,1)+transition:long_term_end(1),1) *2*coeffs(10,2)+ coeffs(10,6)),'m:');  % Hxl
title([path ': SDF LogLog']);
text(0,0,['R^2 ' num2str(coeffs(7,4)) ',  ' num2str(coeffs(10,4))]);
ylabel('Log10 MSD ML (mm^2)');


subplot(3,1,2)
hold on
plot(lsdf(:,1),lsdf(:,3),'r')
plot(lsdf(1:ct(2,1)-transition,1),    (lsdf(1:ct(2,1)-transition,1)   *2*coeffs(8,2) + coeffs(8,6))  ,'m:');  % Hys
plot(lsdf(ct(2,1)+transition:long_term_end(2),1), (lsdf(ct(2,1)+transition:long_term_end(2),1) *2*coeffs(11,2)+ coeffs(11,6)),'m:');  % Hyl
text(0,0,['R^2 ' num2str(coeffs(8,4)) ',  ' num2str(coeffs(11,4))]);
ylabel('Log10 MSD AP (mm^2)');

subplot(3,1,3)
hold on
plot(lsdf(:,1),lsdf(:,4),'r')
plot(lsdf(1:ct(3,1)-transition,1),    (lsdf(1:ct(3,1)-transition,1)   *2*coeffs(9,2) + coeffs(9,6)) ,'m:');  % Hrs
plot(lsdf(ct(3,1)+transition:long_term_end(3),1), (lsdf(ct(3,1)+transition:long_term_end(3),1) *2*coeffs(12,2)+ coeffs(12,6)),'m:');  % Hrl
xlabel('Log10 Time Interval (s)');
ylabel('Log10 MSD R (mm^2)');
text(0,0,['R^2 ' num2str(coeffs(9,4)) ',  ' num2str(coeffs(12,4))]);

saveas(gcf,[savepath 'sdflog.fig'])


close all

%disp(['Elapsed time for processing this directory: ' num2str(etime(clock,dirtime)/60) ' minutes.']);