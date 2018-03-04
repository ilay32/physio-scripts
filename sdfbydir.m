% 
% COP by File
% based on sdf_by_dir.m
% needed: 
%   medio lateral range
%   anterior posterior range
%   mean velocities
%   mean area
    
source('cophelpers.m');
%clear all
lt_end_sec = 10; %input('Default end of long-term region in seconds? '); % Scalar
transition = 0; %input('Number of samples on either side of Critcial/Transition Point to eliminate from regression?');

function ret = dirmode()
    path = uigetdir();
    files = dir(path);
    disp(files);
	for filenum = 1:size(files,1)
   	    filename = getfield(files,{filenum,1},'name');
        cop(filename);
    end
    ret = 1;
end
function ret = filemode()
    [file path] = uigetfile('*.dat');
    cop([path file])
    ret = 1;
end



function l = cop(filepath)
    global lt_end_sec;
    start = clock;
    disp(['Processing ' filepath]);
    [data,forces,sample_rate] = bioware_read3(filepath,0); % No filtering, forces not used here
    copx(:,1) = data(:,1);
    copy(:,1) = data(:,2);

    if any(isnan(copx)) || any(isnan(copy))
        disp([filepath ' rejected due to unrealistic COP values']);
        l = 0;
        return;
    end;
    lt_end = lt_end_sec*sample_rate; % Convert from seconds to # of samples
    [rows,cols] = size(copx);
    SEC=floor(rows/sample_rate);
    % Yaron : Decided to take last 30s without truncating anything   
    % Yaron: 17/7 - Trim the first 3 seconds
    copx = copx(end-SEC*sample_rate+1:end,:); % Take last 30s after discarding 1 second from end
    copy = copy(end-SEC*sample_rate+1:end,:);
   
    % now cut additional 3 secs. from the start
    copx = copx(3*sample_rate+1:end,:); % Take last 30s after discarding 1 second from end
    copy = copy(3*sample_rate+1:end,:);

    % Yaron 17/7 : Get the length...
    length = size(copx, 1)/sample_rate;

    % Eliminate any trials with Nans (indicating unrealistically large COP values)
    %temp = [copx; copy];
    %bad = find(any(isnan(temp)));
    %if ~isempty(bad),
    %    disp(['Trial number(s) ' num2str(bad) ' rejected due to unrealistic COP values']);
    %    copx(:,bad)=[];
    %    copy(:,bad)=[];
    %end;
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
    save(['copmeasmod.csv'],'output','-ascii','-tabs');
    disp([filepath ' done']);
    l = 1;
end;   

% create the gui panel
h = figure();
close = uicontrol(h, "string", "CLOSE", "position",[200 10 150 30], "callback","delete(gcf)");
d = uicontrol(h,"string","choose dir","position",[10 300 100 30],"callback","dirmode()");
f = uicontrol(h,"string","choose file", "position",[150 300 100 30],"callback","filemode()");
uiwait(h);


exit

