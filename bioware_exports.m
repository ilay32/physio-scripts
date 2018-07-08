function [files] = bioware_exports(directory)
    % BIOWARE_EXPORTS takes directory path and returns a cell array of all TSV (txt) bioware exports in the given directory
    potential = dir([directory '\*.txt']);
    files = {};
    for i = 1:length(potential)       
        include = 0;
        f = potential(i).name;
        fid = fopen([directory '\'  f]);
        curline = fgetl(fid);
        % first try to see if the first line is 'BioWare xx Export'
        if ~isempty(regexp(curline,'BioWare(\s*Version\s*)[\d\.\s]+Export','match'))
            include = 1;        
        %if it's not, seek some known patterns up to 50 lines
        else
            giveup = 50;
            while ischar(curline) && giveup > 0 && include == 0
                % line is data line
                isdline = ~isempty(regexp(curline,'^([\d\.\-]{6,12}(\t)?){2,20}$','match'));
                % line is column names line
                istline = any(strfind(curline,'abs time') == 1);
                if istline || isdline
                    include = 1;
                else
                    % uncomment if data is never found
                    % fprintf('skipping %s. is data line: %d, is target line:%d\n',curline,isdline,istline);
                end    
                curline = fgetl(fid);
                giveup = giveup - 1;
            end
        end
        fclose(fid);
        if include
            files{i} =  f;
        end
    end
end




