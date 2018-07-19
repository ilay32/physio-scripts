function [cop,forces,sample_rate] = parsetsv(tsv)
    % Reads Bioware Text Export 
    % Usage: [cop_net,forces,sample_rate] = parsetsv(filename,filtcop,dist)
    % Output format for (raw) forces is [Fx,Fy,Fz]
    % If filtcop = 1, Data is filtered by 4th Order Zero Phase Butterworth Filter, 15Hz
    % sample rate is taken from the time column regardless of file header 
    fid = fopen(tsv);
    tline = fgetl(fid);
    linenumber = 1;
    colnames = {};
    datastart = -1;
    % read the file line by line, until the column names and the data are
    % met
    while ischar(tline)
        % first column -- time will always be there
        if strfind(tline,'abs time') == 1
            colnames = strsplit(tline,'\t');
        % precise regex match verifies it's a data line
        elseif size(colnames,2) > 0
            pat = ['^([\d\.\-]{6,12}(\t)?){' num2str(size(colnames,2)) '}$'];
            if regexp(tline,pat ) > 0
                datastart = linenumber;
                break
            end
        end    
        tline = fgetl(fid);
        linenumber = linenumber + 1;
    end
    fclose(fid);
    % find the indices of the cop columns
    data = dlmread(tsv,'\t',datastart,0);
    
    % go over the colnames and assign the right answers to return
    for i=1:size(colnames,2)
        if strcmp(colnames{i},'Ax')
            cop(:,1) = data(:,i)*1000; % multiply by 1000 to match the old .dat read script output
        elseif strcmp(colnames{i},'Ay')
            cop(:,2) = data(:,i)*1000; % here too
        elseif strcmp(colnames{i},'Fx')
            forces(:,1) = data(:,i);
        elseif strcmp(colnames{i},'Fy')
            forces(:,2) = data(:,i);
        elseif strcmp(colnames{i},'Fz')
            forces(:,3) = data(:,i);
        elseif strcmp(colnames{i},'abs time (s)')
            sample_rate = 1/(data(2,i) - data(1,i));
        end
    end
end
