% SIMPLECOP.M  Calculates traditional COP parameters
% produces one row per data file
% row format: mean x   mean y   range x     range y     sway area/s 

% figure out which folders to work on
clear; clc;
folder = uigetdir('C:\Users\Public\Yogev\','Data Directory -- Where the conditions CSV is');

% ask for the the "long term" and "transition" parameters
chopstart = input('seconds to chop from start of trial: ');
chopend = input('seconds to chop from end of trial: ');

  
% scan the folder for boiware exports, and foreach export file, call
% the params computation and enter that row
exports = recexports(folder);

assert(~isempty(exports),'cant find BioWare exports in this folder');


lines = cell(length(exports),1);
registered = 1;

% loop the found files and register a row of params for each
% if 'conditions.csv' was found, the original order is maintained
for f = exports
    disp(['Entering ' f{:}]);
    [cop,~,sample_rate] = parsetsv(f{:});
    cop = cop(chopstart*sample_rate:end - chopend*sample_rate,:);
    params = cparams(cop,sample_rate,15,7.5); % based on Itzik's scripts
    params = [params sdfjist(cop,sample_rate)];
    lines{registered} = findline(f{:},params);
    registered = registered + 1;
end

% write computed params
datheader = 'cop range x,cop range y,sway area/s,isway,mean velocity,crtx,crtxinter,crty,crtyinter,crtr,crtinter,dxs,dys,drs';
header = 'condition,taken from';
savefile = fopen(fullfile(folder,'conditions-and-params.csv'),'wt');
fprintf(savefile,'initial chop:%0.1f sec,final chop: %0.1f sec\n%s,%s\n',chopstart,chopend,header,datheader);
for l = lines
    fprintf(savefile,'%s\n',l{:});
end
fclose(savefile);
disp('all params written');

function [newline] = findline(f,datrow)
    % looks for the right line in 'conditons.csv' if exists,
    % and returns it along with the data
    datstring = sprintf(repmat(',%f',1,length(datrow)),datrow);
    [~,basename,ext] = fileparts(f);
    [~,t] = regexp(basename,'([^\-]+)\-(\d+)$','match','tokens');
    if size(t{1,1},2) == 2
        newline = [t{1,1}{1} ',' basename ext datstring];
    else
        newline = ['?,' basename ext];
    end
end

function [files] = recexports(folder)
    files = bioware_exports(folder);
    files = cellfun(@(f)fullfile(folder,f),files,'UniformOutput',false);
    d = dir(folder);
    isub = [d(:).isdir];
    dirnames = {d(isub).name};
    if isempty(dirnames)
        return;
    end
    for sub=dirnames(3:end)
       files = [files recexports(fullfile(folder,sub{:}))];
    end
end

function [output]= cparams(cop,sampling_rate,filt1,filt2)
    % COPPARAM Calculates traditional COP statistics 
    % Usage: [output]= copparam(copx,copy,sampling_rate,filt_cutoff)
    % Output is a row vector with elements:
    % 1  mean COP X
    % 2  mean COP Y
    % 3 COP range X 
    % 4  COP range Y
    % 5 Sway Area per second - area enclosed by COP (??R)
    % !!COPs are given in millimeters!!
    % This is based on Peter Meyer's original made for Itzik Meltzer
    % back in the day. The sway area is a little different -- it uses
    % MATLAB built in functions to get the area of the convex hull defined by the set of COP points.
    
    seconds = 0;
    
    function updatesecs()
        seconds = length(cop)/sampling_rate;
    end

    function lpfilt(filt,s,e)
        [B,A] = butter(2,filt/(sampling_rate/2));
        cop = filtfilt(B,A,cop);
        cop = cop(s:e,:); % Remove edge effects
        updatesecs();
    end
    
    updatesecs();
    % Filter data if filt1
    if filt1 ~=0
        tst = cop(1:10,:);
        cutbase = floor(200/filt1); % to check
        lpfilt(filt1,cutbase + 1,length(cop) - cutbase);
        assert(~any(all(cop(1:10,:) == tst)),'filter has no effect');
        clear tst;
    end

    % Mean COP, range COP
    m = mean(cop);
    r = max(cop) - min(cop);
    
    % center around 0
    cop = (cop' - m')';
    
    % Sway Area/s
    vertices = cop(convhull(cop),:);
    sway_area = polyarea(vertices(:,1),vertices(:,2));
    area_ps = sway_area/seconds;
    
    isway = 0;
    for i = 1:length(cop) - 1
        isway = isway  + abs(det(cop(i:i+1,:)));
    end
    isway = 0.5*isway/seconds;

    % Mean Velocity
    if filt2 ~= 0
        tst = cop(1:100,:);
        lpfilt(filt2,101,length(cop)-100);
        assert(~any(all(cop(1:100,:) == tst)),'filter has no effect');
        clear tst;
    end
    copvel = sum(sqrt(sum(diff(cop) .^ 2,2)));
    output = [r,area_ps,isway,mean(copvel)/seconds];
end

function sdparams = sdfjist(cop,sample_rate)
    SEC  = size(cop,1)/sample_rate;
    
    %Calculate ensemble SD function
    % Yaron 17/7 added 'length' (now 'SEC') as parameter for stabilogram_diffusion...
    [sdfx]=stabilogram_diffusion(cop(:,1),sample_rate,SEC,2,0); 
    [sdfy]=stabilogram_diffusion(cop(:,1),sample_rate,SEC,2,0);
    sdf(:,1) = (1/sample_rate:1/sample_rate:SEC -(1/sample_rate))';
    sdf(:,2) = sdfx(:,2);
    sdf(:,3) = sdfy(:,2);
    sdf(:,4) = sdf(:,2) + sdf(:,3);
      
    % Calculate SDF Parameters
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
    %   CP by loglog slope  CP by intersection
    % 1 Ctx
    % 2 Cty
    % 3 Ctr
    % 4 Cdx
    % 5 Cdy
    % 6 Cdr

    %No checking of r^2, 200ms transition region. Long_term_end is a 1x3 vector
    % transition 0 long term 10secs
    [coeffs,cp,~] = sdf_parameters(sdfx(:,1),sdf(:,2:3),0,0,10*sample_rate);
    ctr = cp(1:3,:);
    sdparams = [ctr,coeffs(1:3,2)];
end