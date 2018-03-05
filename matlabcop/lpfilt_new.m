function [lpf,begin] =lpfilt(emg,cutoff,inputfreq,outputfreq,ring,type,order)
% LPFILT.M	LPF columns of data, remove the ring if required
% Usage:	[lpf,begin] =lpfilt(emg,cutoff,inputfreq,outputfreq,ring,type,order)
%		Input data specified by the matrix emg. Filter specified by windowsize and
%		measured in points at the desired output frequency outputfreq. inputfreq and
%		outputfreq specify the input frequency of emg and the desired frequency
%		of the filtered output respectively. Lpfilt.m returns the filtered 
%		matrix lpf. 'Cutoff', 'inputfreq', 'outputfreq' in Hz.
%
%		ring ='y' removes the filter transients from the beginning and end of 
%		the lpf vector. ring = 'n' removes only the delay caused by the filter.
%		Begin returns the number of points removed +1 from the start of the vector
%		for use in aligning a time vector.
%		type = 'butter' or 'cheby'
%		order = filter order
% Usage [lpf,begin] = lpfilt(emg,cutoff,inputfreq,outputfreq,ring,type,order)
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
   		temp1 = decimate(emg(:,column),inputfreq/outputfreq);	%Downsampling
   	else
		temp1 = emg(:,column);
   	end;
   	lpf(:,column) = filtfilt(B,A,(temp1)); 			% LP Filter
end;


% Remove transients
if strcmp(ring,'y') ==1
   begin = N+1;
   lpf = lpf(begin:size(lpf,1)-(begin-1),:);		% Remove Transients
elseif strcmp(ring,'n') ==1
   % begin = 0;
   % lpf = lpf(1+floor(N/2):size(lpf,1),:);		% Remove only Delay
   % disp('Use y-option to remove transients. No delay caused by filtfilt function');
end;









   

