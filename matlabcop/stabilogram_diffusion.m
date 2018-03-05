function [mean_sdf] = stabilogram_diffusion(COP,sampling_rate,max_interval,p,lmd)
% STABILOGRAM_DIFFUSION		Calculates diffusion plot of input data COP. Each trial is a column in COP.
% Usage:	[MEAN_SDF] = stabilogram_diffusion(COP,sampling_rate,max_interval,p,lmd)
%			COP: matrix of COP time series in mm, one trial per column. No time column expected
%			sampling_rate: sampling_rate in Hz
%			max_interval: Largest time interval desired. Units are seconds
%			p: plotting option. p=1 plots the stabilogram diffusion function for each trial and the mean, 
%				p= 2 is used with lmd= 1 to plot the effect of removing the worst trials on the mean SDF
%			lmd: Minimizes variability between trials. lmd = 1 uses only the 10 trials that deviate the least from the mean SDF.
% Output: MEAN_SDF = [interval ensemble_avg_sdf ]
% Pete Meyer 12/19/2000


N = size(COP,1);	% Number of points
num_of_trials = size(COP,2); % Number of trials

if nargin > 2 % Convert max_interval from seconds to samples
   max_interval = max_interval*sampling_rate-1;
else        
   max_interval = N-1;
end;

if nargin < 5
   lmd = 0;
   if nargin < 4
      p = 0;
   end;
end;


% Calculate SDF for each trial
	sdf_trials = ones(max_interval,num_of_trials+1); % Initialize variable

	% Create interval vector
	for interval = 1:max_interval
   	sdf_trials(interval,1) = interval/sampling_rate;
	end;

	for trial = 1:num_of_trials
		for interval = 1:max_interval
   		sdf_trials(interval,trial+1) = mean((COP(1:N-interval,trial)-COP(1+interval:N,trial)).^2);
		end;
	end;

% Calculate resultant sdf
mean_sdf = zeros(max_interval,2); % Initialize variable
mean_sdf(:,1) = sdf_trials(:,1);
mean_sdf(:,2) = mean(sdf_trials(:,2:num_of_trials+1),2);



if lmd == 1  % Determine 10 trials that deviate the least from the mean
	mse_sdf = ones(1,num_of_trials); % Initialize variable
   % Calculate MS Difference from mean over 20s for each trial
   for i = 1:num_of_trials
   	mse_sdf(1,i) = mean(((sdf_trials(1:2000,i+1)-mean_sdf(1:2000,2)).^2),1); % MS diff from mean
	end;
	[x,tnum] = sort(mse_sdf); % Sort by mse
	disp(['Worst trials are ' num2str(tnum(11)) ' & ' num2str(tnum(12))]);

	new_mean_sdf = ones(size(sdf_trials,1),2);		% Initialize variable
	new_sdf_trials = ones(size(sdf_trials,1),11);	% Initialize variable
	for i = 1:10
   	new_sdf_trials(:,i+1) = sdf_trials(:,tnum(i)+1); % sdf_trials includes a time interval column
	end;
	new_mean_sdf(:,2) = mean(new_sdf_trials(:,2:11),2);
   new_mean_sdf(:,1) = mean_sdf(:,1);
   
   if p==2	% Plot difference in SDF when bad trials are removed
		figure
		subplot(2,1,1)
		plot(new_mean_sdf(:,1),new_mean_sdf(:,2),':',mean_sdf(:,1),mean_sdf(:,2),'-');
		title('Linear SDF')
		xlabel('Time interval (s)')
		ylabel('Mean Squared Displacement (mm^2)')

		subplot(2,1,2)
   	loglog(new_mean_sdf(:,1),new_mean_sdf(:,2),':',mean_sdf(:,1),mean_sdf(:,2),'-');
   	title('Log Scale')
		xlabel('Time interval (s)')
   	ylabel('Mean Squared Displacement (mm^2)')
   end;
   
   mean_sdf = new_mean_sdf; % Use 10 trial SDF
end;



if p==1		% Plotting Option chosen
   
   linedef = struct('lin',{'b','r','g','c','m','y','k','b:','r:','g:','c:','m:','y:','k:'});
     
	figure
   subplot(2,1,1)
   for i = 2:num_of_trials,
   	hold on, plot(sdf_trials(:,1),sdf_trials(:,i),getfield(linedef,{1,i},'lin'));
      hold on, plot(mean_sdf(:,1),mean_sdf(:,2),'o');
   end;
   title('Linear SDF')
	xlabel('Time interval (s)')
	ylabel('Mean Squared Displacement (mm^2)')

	subplot(2,1,2)
	for i = 2:num_of_trials,
		hold on, loglog(sdf_trials(:,1),sdf_trials(:,i),getfield(linedef,{1,i},'lin'));
   	hold on, loglog(mean_sdf(:,1),mean_sdf(:,2),'o');
   end;
   title('Log Scale')
	xlabel('Time interval (s)')
	ylabel('Mean Squared Displacement (mm^2)')
end;

