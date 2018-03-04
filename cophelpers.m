
function [lpf,begin] =lpfilt_new(emg,cutoff,inputfreq,outputfreq,ring,type,order)
% LPFILT.M  LPF columns of data, remove the ring if required
% Usage:    [lpf,begin] =lpfilt(emg,cutoff,inputfreq,outputfreq,ring,type,order)
%       Input data specified by the matrix emg. Filter specified by windowsize and
%       measured in points at the desired output frequency outputfreq. inputfreq and
%       outputfreq specify the input frequency of emg and the desired frequency
%       of the filtered output respectively. Lpfilt.m returns the filtered 
%       matrix lpf. 'Cutoff', 'inputfreq', 'outputfreq' in Hz.
%
%       ring ='y' removes the filter transients from the beginning and end of 
%       the lpf vector. ring = 'n' removes only the delay caused by the filter.
%       Begin returns the number of points removed +1 from the start of the vector
%       for use in aligning a time vector.
%       type = 'butter' or 'cheby'
%       order = filter order
% Usage [lpf,begin] = lpfilt(emg,cutoff,inputfreq,outputfreq,ring,type,order)
pkg load signal
if nargin <6
    type = 'cheby';
end;
if nargin <7
    order= 4;
end;

N = order;

% Filter type
if strcmp(type,'cheby') == 1
    [B,A] = cheby2(N,20,cutoff/(outputfreq/2));
elseif strcmp(type,'butter') == 1
    [B,A] = butter(N,cutoff/(outputfreq/2));
else
    error('Illegal filter type selected.');
end;

% Apply filter
for column = 1:size(emg,2)
    if outputfreq ~= inputfreq
        temp1 = decimate(emg(:,column),inputfreq/outputfreq);   %Downsampling
    else
        temp1 = emg(:,column);
    end;
    lpf(:,column) = filtfilt(B,A,(temp1));          % LP Filter
end;

% Remove transients
if strcmp(ring,'y') ==1
   begin = N+1;
   lpf = lpf(begin:size(lpf,1)-(begin-1),:);        % Remove Transients
elseif strcmp(ring,'n') ==1
   % begin = 0;
   % lpf = lpf(1+floor(N/2):size(lpf,1),:);     % Remove only Delay
   % disp('Use y-option to remove transients. No delay caused by filtfilt function');
end;
end;


function [cop_net,forces,sample_rate]= bioware_read3(filename,filtcop,dist)
% BIOWARE_READ3		Reads COP data from Bioware generated binary file 
% Usage: [cop_net,forces,sample_rate] = bioware_read3(filename,filtcop,dist)
%			Output format for cop_net is [COPx COPy]
%			Output format for (raw) forces(:,16) is Fx1,Fy1,Fz1,Mx1,My1,Mz1,Copx1,Copy1,Fx2,Fy2,Fz2,Mx2,My2,Mz2,Copx2,Copy2
%	  		If filtcop = 1, Data is filtered by 4th Order Zero Phase Butterworth Filter, 15Hz
%			If 2 plates are used, dist is the distance between the center of plate 1 & center of plate 2 in x-direction.
%			(Tandem placement assumed)
%			Assumes No auxillary data channels are used.
% 
% Version 3.0 Peter Meyer 10/26/01: Provides net COP from 2 forceplates
% Version 3.2 Peter Meyer 04/12/02: Substitutes NaN's for COP's greater than forceplate size.
%												(Assumes Kistler 9284, 500mm x 500mm)
% Version 3.3 Peter Meyer 9/5/02: Provides sampling rate as output. Filter option no longer assumes 100Hz

%warning off

	fid = fopen(filename,'r');
	fread(fid,80,'uchar'); % File title header
	fread(fid,14,'uchar'); % Time
	fread(fid,14,'uchar'); % Date
	fread(fid,31,'uchar'); % patient name
	fread(fid,31,'uchar'); % patient ID
	fread(fid,51,'uchar'); % Trial description 1
	fread(fid,51,'uchar'); % Trial description 2
	sample_rate = fread(fid,1,'float32'); % Sample rate
	sample_time = fread(fid,1,'float32'); % Sample time
	fread(fid,1,'int16'); % # A/D channels
	num_plates = fread(fid,1,'int16'); % # Force Plates
	fread(fid,1,'float32'); % Plate 1 width
	fread(fid,1,'float32'); % Plate 2 width
	fread(fid,1,'float32'); % Plate 1 length
	fread(fid,1,'float32'); % Plate 2 length
	plate1_a = fread(fid,1,'float32')* 10; % Plate 1 a in mm!
	plate2_a = fread(fid,1,'float32')* 10; % Plate 2 a
	plate1_b = fread(fid,1,'float32')* 10; % Plate 1 b in mm!
	plate2_b = fread(fid,1,'float32')* 10; % Plate 2 b
	plate1_Az = fread(fid,1,'float32')* 10; % Plate 1 Az in mm!
	plate2_Az = fread(fid,1,'float32') * 10; % Plate 2 Az
	plate1_X_sensitivity = fread(fid,1,'float32'); % Plate 1 X sensitivity
	plate2_X_sensitivity = fread(fid,1,'float32'); % Plate 2 X sensitivity
	plate1_Y_sensitivity = fread(fid,1,'float32'); % Plate 1 Y sens
	plate2_Y_sensitivity = fread(fid,1,'float32'); % Plate 2 Y sens
	plate1_Z_sensitivity = fread(fid,1,'float32'); % Plate 1 Z sens
	plate2_Z_sensitivity = fread(fid,1,'float32'); % Plate 2 Z sens
	fread(fid,1,'int16'); % data taken in reverse
	chargeamp1_XY_range = fread(fid,1,'float32'); % ChargeAmp1 XY range
	chargeamp2_XY_range = fread(fid,1,'float32'); % ChargeAmp2 XY range
	chargeamp1_Z_range = fread(fid,1,'float32'); % ChargeAmp1 Z range
	chargeamp2_Z_range = fread(fid,1,'float32'); % ChargeAmp2 Z range
	fread(fid,1,'uchar'); % Aux device 1 enabled
	fread(fid,1,'uchar'); % Aux device 2 enabled
	fread(fid,1,'uchar'); % Aux device 3 enabled
	fread(fid,1,'uchar'); % Aux device 4 enabled
	fread(fid,1,'uchar'); % Aux device 5 enabled
	fread(fid,1,'uchar'); % Aux device 6 enabled
	fread(fid,1,'uchar'); % Aux device 7 enabled
	fread(fid,1,'uchar'); % Aux device 8 enabled
	fread(fid,1,'float32'); % Aux device 1 MU
	fread(fid,1,'float32'); % Aux device 2 MU
	fread(fid,1,'float32'); % Aux device 3 MU
	fread(fid,1,'float32'); % Aux device 4 MU
	fread(fid,1,'float32'); % Aux device 5 MU
	fread(fid,1,'float32'); % Aux device 6 MU
	fread(fid,1,'float32'); % Aux device 7 MU
	fread(fid,1,'float32'); % Aux device 8 MU
	fread(fid,10,'uchar'); % Aux device 1 label
	fread(fid,40,'uchar'); % Aux device 1 title 
	fread(fid,10,'uchar'); % Aux device 2 label
	fread(fid,40,'uchar'); % Aux device 2 title
	fread(fid,10,'uchar'); % Aux device 3 label
	fread(fid,40,'uchar'); % Aux device 3 title
	fread(fid,10,'uchar'); % Aux device 4 label
	fread(fid,40,'uchar'); % Aux device 4 title
	fread(fid,10,'uchar'); % Aux device 5 label
	fread(fid,40,'uchar'); % Aux device 5 title
	fread(fid,10,'uchar'); % Aux device 6 label
	fread(fid,40,'uchar'); % Aux device 6 title
	fread(fid,10,'uchar'); % Aux device 7 label
	fread(fid,40,'uchar'); % Aux device 7 title
	fread(fid,10,'uchar'); % Aux device 8 label
	fread(fid,40,'uchar'); % Aux device 8 title
	rawdata = fread(fid,[(num_plates * 8),inf],'int16'); % Read in data from 1 or 2 plates w/o aux devices
	rawdata = rawdata'; % Fx12 Fx34 Fy14 Fy23 Fz1 Fz2 Fz3 Fz4	 
	fclose(fid);
	%disp('Data read');
   
    
   if (num_plates == 1)
	% Convert rawdata from bits to newtons
		rawdata(:,1:2) = -rawdata(:,1:2) * .004882 * (chargeamp1_XY_range)/plate1_X_sensitivity;
		rawdata(:,3:4) = -rawdata(:,3:4) * .004882 * (chargeamp1_XY_range)/plate1_Y_sensitivity;
		rawdata(:,5:8) = -rawdata(:,5:8) * .004882 * (chargeamp1_Z_range)/plate1_Z_sensitivity;
		%disp('Data in newtons');

	% Convert to reduced data in N, Nmm, and mm
		reduced(:,1) = rawdata(:,1) + rawdata(:,2); % Fx
		reduced(:,2) = rawdata(:,3) + rawdata(:,4); % Fy
		reduced(:,3) = rawdata(:,5) + rawdata(:,6) + rawdata(:,7) + rawdata(:,8); % Fz
		reduced(:,4) = plate1_b*(rawdata(:,5) + rawdata(:,6) - rawdata(:,7) - rawdata(:,8)); % Mx
		reduced(:,5) = plate1_a*(-rawdata(:,5) + rawdata(:,6) + rawdata(:,7) - rawdata(:,8)); % My
		reduced(:,6) = plate1_b*(-rawdata(:,1) + rawdata(:,2)) - plate1_a*(rawdata(:,3) - rawdata(:,4)); % Mz
		reduced(:,7) = (reduced(:,1)*plate1_Az - reduced(:,5))./reduced(:,3); % COPx
      reduced(:,8) = (reduced(:,2)*plate1_Az + reduced(:,4))./reduced(:,3); % COPy
      reduced(:,9:16) = zeros(size(reduced)); % Zeros for 2nd force plate
      
      reduced(find(abs(reduced(:,7))>250),7) = nan; % Eliminate any COP values greater than the forceplate
      reduced(find(abs(reduced(:,8))>250),8) = nan;
      
      cop_net(:,1:2) = reduced(:,7:8);
      
   elseif (num_plates == 2)
	% Convert rawdata from bits to newtons
      rawdata(:,1:2) = -rawdata(:,1:2) * .004882 * (chargeamp1_XY_range)/plate1_X_sensitivity;
		rawdata(:,3:4) = -rawdata(:,3:4) * .004882 * (chargeamp1_XY_range)/plate1_Y_sensitivity;
      rawdata(:,5:8) = -rawdata(:,5:8) * .004882 * (chargeamp1_Z_range)/plate1_Z_sensitivity;
      rawdata(:,9:10) = -rawdata(:,9:10) * .004882 * (chargeamp2_XY_range)/plate2_X_sensitivity;
		rawdata(:,11:12) = -rawdata(:,11:12) * .004882 * (chargeamp2_XY_range)/plate2_Y_sensitivity;
      rawdata(:,13:16) = -rawdata(:,13:16) * .004882 * (chargeamp2_Z_range)/plate2_Z_sensitivity;
	% Convert to reduced data in N, Nmm, and mm
		reduced(:,1) = rawdata(:,1) + rawdata(:,2); % Fx
		reduced(:,2) = rawdata(:,3) + rawdata(:,4); % Fy
		reduced(:,3) = rawdata(:,5) + rawdata(:,6) + rawdata(:,7) + rawdata(:,8); % Fz
		reduced(:,4) = plate1_b*(rawdata(:,5) + rawdata(:,6) - rawdata(:,7) - rawdata(:,8)); % Mx
		reduced(:,5) = plate1_a*(-rawdata(:,5) + rawdata(:,6) + rawdata(:,7) - rawdata(:,8)); % My
		reduced(:,6) = plate1_b*(-rawdata(:,1) + rawdata(:,2)) - plate1_a*(rawdata(:,3) - rawdata(:,4)); % Mz
		reduced(:,7) = (reduced(:,1)*plate1_Az - reduced(:,5))./reduced(:,3); % COPx
      reduced(:,8) = (reduced(:,2)*plate1_Az + reduced(:,4))./reduced(:,3); % COPy
      reduced(:,9) = rawdata(:,9) + rawdata(:,10); % Fx2
		reduced(:,10) = rawdata(:,11) + rawdata(:,12); % Fy2
		reduced(:,11) = rawdata(:,13) + rawdata(:,14) + rawdata(:,15) + rawdata(:,16); % Fz2
		reduced(:,12) = plate2_b*(rawdata(:,13) + rawdata(:,14) - rawdata(:,15) - rawdata(:,16)); % Mx2
		reduced(:,13) = plate2_a*(-rawdata(:,13) + rawdata(:,14) + rawdata(:,15) - rawdata(:,16)); % My2
		reduced(:,14) = plate2_b*(-rawdata(:,9) + rawdata(:,10)) - plate2_a*(rawdata(:,11) - rawdata(:,12)); % Mz2
		reduced(:,15) = (reduced(:,9)*plate2_Az - reduced(:,13))./reduced(:,11); % COPx2
      reduced(:,16) = (reduced(:,10)*plate2_Az + reduced(:,12))./reduced(:,11); % COPy2
      
      % Adjust meaningless values of COP (>250mm)
      % Set COP(COP>250) to zero for purposes of calculating net COP
      	weight = ones(size(reduced,1),4);
      	weight(reduced(:,[7:8 15:16])>250) = 0; % Will be used to eliminate whole term if COP is >250
        adj_COP = reduced(:,[7:8 15:16]);		 % temporarily sets COP>250 to 0 so that whole term can be made 0
      	adj_COP(abs(adj_COP)>250) = 0;
      % Set COP(COP>250) to nan for purposes of saving individual COPs from each forceplate
         reduced(find(abs(reduced(:,7))>250),7) = nan; % Eliminate any COP values greater than the forceplate
         reduced(find(abs(reduced(:,8))>250),8) = nan;  % Eliminate any COP values greater than the forceplate
         reduced(find(abs(reduced(:,15))>250),15) = nan; % Eliminate any COP values greater than the forceplate
         reduced(find(abs(reduced(:,16))>250),16) = nan; % Eliminate any COP values greater than the forceplate
         
         
      % COPx = weight*(-dist/2 + COPx1)*Fz1  + weight*(dist/2 + COPx2)*Fz2) /(Fz1+Fz2);
      cop_net(:,1) = weight(:,1).*((-dist/2 + adj_COP(:,1)).*reduced(:,3)  + weight(:,3).*(dist/2 + adj_COP(:,3)).*reduced(:,11))./(reduced(:,3)+reduced(:,11));
      cop_net(:,2) = ((adj_COP(:,2)).*reduced(:,3)  + (adj_COP(:,4)).*reduced(:,11))./(reduced(:,3)+reduced(:,11));
  end
   

   	
   % Filter the data at 15Hz, 4th order zero phase
   if exist('filtcop') == 1 & filtcop == 1
      forces = lpfilt(reduced,15,sample_rate,sample_rate,'n','butter',2);
      cop_net = lpfilt(cop_net,15,sample_rate,sample_rate,'n','butter',2);
      disp('Data lp filtered at 15Hz')
  else
      forces = reduced;   
  end
   
   % Check output
   
   %figure
   %plot(forces(:,7)+255,forces(:,8),'b')
   %hold on,
   %plot(forces(:,15)-255,forces(:,16),'r');
   %hold on,
   %plot(cop_net(:,1),cop_net(:,2),'m');
   %axis equal  
   %set(gca,'Xdir','reverse');
   
   
   %figure
   %subplot(1,3,1)
   %plot(forces(:,7),forces(:,8),'b')
   %set(gca,'Xdir','reverse');
   %subplot(1,3,2)
   %plot(cop_net(:,1),cop_net(:,2),'m');
   %set(gca,'Xdir','reverse');
   %subplot(1,3,3)
   %plot(forces(:,15),forces(:,16),'r');
   %set(gca,'Xdir','reverse');
   
   %figure,
   %subplot(4,1,1)
   %plot(forces(:,3),'b'), hold on, plot(forces(:,11),'r');
   %ylabel('Vert F');
   %subplot(4,1,2)
   %plot(forces(:,7),'b')
   %ylabel('LFoot');
   %subplot(4,1,3)
   %plot(forces(:,15),'r');
   %ylabel('RFoot');
   %subplot(4,1,4)
   %plot(cop_net(:,1),'m');
   
   %pause
   
end;





   



function [output]= copparam(copx,copy,sampling_rate,filt_cutoff)
% COPPARAM Calculates traditional COP statistics 
% Usage: [output]= copparam(copx,copy,sampling_rate,filt_cutoff)
% where copx,copy are matrices containing COP time series, one column per trial
% sampling_rate is the data sampling rate in Hz, and filt_cutoff is the cutoff 
% frequency of a 4th order zero-phase Butterworth filter initially applied to the data. 
% Filt_cutoff = 0 does not initially filter the data. Note that a 7.5Hz filter is applied
% before MF and Path are calculated regardless of the value set for filt_cutoff.
% Output is a row vector with elements:
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
%
% Peter Meyer 6/2001
pkg load signal
if nargin <2
   error('Both X & Y data expected');
elseif nargin <3
   sampling_rate = 100;
   filt_cutoff = 0;
elseif nargin <4
   filt_cutoff = 0;
end;

[rows,cols] = size(copx);
% Filter data if required
if filt_cutoff ~=0
	copx = lpfilt_new(copx,filt_cutoff,100,100,'n','butter',2); % 4th order zero phase Butterworth
	copy = lpfilt_new(copy,filt_cutoff,100,100,'n','butter',2);
	copx= copx(floor(200/filt_cutoff) +1:rows-floor(200/filt_cutoff),:); % Remove edge effects
	copy= copy(floor(200/filt_cutoff) +1:rows-floor(200/filt_cutoff),:);
   [rows,cols] = size(copx);
end;

% Mean COP, range COP
   trial_means_x = mean(copx,1);	% Row Vector- Average position of COP for each trial
   	meancop_x = mean(trial_means_x);	% Scalar- Average of mean COP from each trial
		meancop_x_sd = std(trial_means_x); % Scalar- Standard Deviation of trial means
   trial_range_x = max(copx,[],1)- min(copx,[],1);	% Row Vector- COP range for each trial
   	rangecop_x = mean(trial_range_x); % Scalar- Average of COP range from each trial
      
   trial_means_y = mean(copy,1);	% Row Vector- Average position of COP for each trial
   	meancop_y = mean(trial_means_y);	% Scalar- Average of mean COP from each trial
		meancop_y_sd = std(trial_means_y); % Scalar- Standard Deviation of trial means
   trial_range_y = max(copy,[],1)- min(copy,[],1);	% Row Vector- COP range for each trial
   	rangecop_y = mean(trial_range_y); % Scalar- Average of COP range from each trial
      
      
% Make each trial zero mean
  for trial = 1:cols
     copx(:,trial) = copx(:,trial) - trial_means_x(trial);
     copy(:,trial) = copy(:,trial) - trial_means_y(trial);
  end;
        
% Sway Area/s
sway_area = zeros(1,cols);
for trial = 1:cols
   for sample = 1:rows-1
      sway_area(trial) = sway_area(trial) + abs(copy(sample+1,trial)*copx(sample,trial) - copy(sample,trial)*copx(sample+1,trial));
   end;
end;
mean_sway_area_ps = .5*mean(sway_area)*(sampling_rate)/rows;


% Filter the data again at 7.5Hz
copxf = lpfilt_new(copx,7.5,100,100,'n','butter',2); % 4th order zero phase Butterworth
copyf = lpfilt_new(copy,7.5,100,100,'n','butter',2);
copxf= copxf(101:rows-100,:); % Remove edge effects
copyf= copyf(101:rows-100,:);
[rows] = size(copxf,1);		% Redefine # of rows


% Median Frequency
% [Pxx,F] = PSD(X,NFFT,Fs,WINDOW,NOVERLAP,DFLAG)
%for trial = 1:cols
%   [ps(:,1)]    = psd(copxf(:,trial),2048,100,2000,1950,'mean'); % X dir psd Take windows every 1/2 second
%   [ps(:,2), f] = psd(copyf(:,trial),2048,100,2000,1950,'mean'); % Y dir Psd
%      
%   power=sum(ps(2:size(ps,1),:),1);					% Total power in each direction  minus DC component   
%   
%   for direction = 1:2
%   	halfpower=0; 
%		i=1; % Skip DC component
%		while (2*halfpower)<power(direction),					% Stop when half total power is reached
%			halfpower=halfpower+ps(i+1,direction);
%			i=i+1;
%		end;			
%      mpf(trial,direction)=f(i);				% Store only the MF's in Hz
%   end;
% end;
% mean_copx_mpf = mean(mpf(:,1)); % Average Median Power Frequency in Hz
% mean_copy_mpf = mean(mpf(:,2));
 
 % Mean Velocity 
   % Initialize vars
	diff_x = ones(rows-1,cols);
   diff_y = diff_x;
   diff_r = diff_x;
   for trial = 1:cols
		for i = 1:rows-1 
   		diff_x(i,trial) = abs(copxf(i+1,trial) - copxf(i,trial));
			diff_y(i,trial) = abs(copyf(i+1,trial) - copyf(i,trial));
   		diff_r(i,trial) = sqrt( (copxf(i+1,trial)-copxf(i,trial))^2 + (copyf(i+1,trial)-copyf(i,trial))^2 );
      end;
   end;
  % mean_velocity_x = mean(sum(diff_x,1),2)*sampling_rate/rows;
  % mean_velocity_y = mean(sum(diff_y,1),2)*sampling_rate/rows;
  % mean_velocity_r = mean(sum(diff_r,1),2)*sampling_rate/rows;
   
   mean_velocity_x = sum(diff_x,1)*sampling_rate/rows;
   mean_velocity_y = sum(diff_y,1)*sampling_rate/rows;
   mean_velocity_r = sum(diff_r,1)*sampling_rate/rows;



   
% Set up output
output(1,1) = meancop_x; 			% Average of mean COP from each trial X & Y
output(2,1) = meancop_y;
output(3,1) = meancop_x_sd; 		% Standard Deviation of trial means X & Y
output(4,1) = meancop_y_sd;
output(5,1) = rangecop_x;			% Average of COP range from each trial X & Y
output(6,1) = rangecop_y;
output(7,1) = 0;		% Average Median Power Frequency X & Y
output(8,1) = 0;
output(9,1) = mean_velocity_x;   % Average of trial Mean velocities X & Y & R
output(10,1)= mean_velocity_y;
output(11,1)= mean_velocity_r;
output(12,1)= mean_sway_area_ps; % Average Sway Area per second- area enclosed by COP R

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
end;
