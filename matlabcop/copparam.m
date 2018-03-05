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
for trial = 1:cols
   [ps(:,1)]    = psd(copxf(:,trial),2048,100,2000,1950,'mean'); % X dir psd Take windows every 1/2 second
   [ps(:,2), f] = psd(copyf(:,trial),2048,100,2000,1950,'mean'); % Y dir Psd
      
   power=sum(ps(2:size(ps,1),:),1);					% Total power in each direction  minus DC component   
   
   for direction = 1:2
   	halfpower=0; 
		i=1; % Skip DC component
		while (2*halfpower)<power(direction),					% Stop when half total power is reached
			halfpower=halfpower+ps(i+1,direction);
			i=i+1;
		end;			
      mpf(trial,direction)=f(i);				% Store only the MF's in Hz
   end;
 end;
 mean_copx_mpf = mean(mpf(:,1)); % Average Median Power Frequency in Hz
 mean_copy_mpf = mean(mpf(:,2));
 
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
   mean_velocity_x = mean(sum(diff_x,1),2)*sampling_rate/rows;
   mean_velocity_y = mean(sum(diff_y,1),2)*sampling_rate/rows;
   mean_velocity_r = mean(sum(diff_r,1),2)*sampling_rate/rows;
   
% Set up output
output(1,1) = meancop_x; 			% Average of mean COP from each trial X & Y
output(2,1) = meancop_y;
output(3,1) = meancop_x_sd; 		% Standard Deviation of trial means X & Y
output(4,1) = meancop_y_sd;
output(5,1) = rangecop_x;			% Average of COP range from each trial X & Y
output(6,1) = rangecop_y;
output(7,1) = mean_copx_mpf;		% Average Median Power Frequency X & Y
output(8,1) = mean_copy_mpf;
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
