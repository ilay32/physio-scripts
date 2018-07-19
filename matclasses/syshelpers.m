classdef syshelpers
    % Some utility functions for getting around the file system
    % assumes windows
    properties
    end
    
    methods(Static)
        function remove_default_sheets(absfileloc)
            if ~exist(absfileloc,'file')
                fprintf('not a file:\n%s\n',absfileloc);
                return;
            end
            try
                [~,sheets,~] = xlsfinfo(absfileloc);
            catch
                fprintf('not an excell file:\n%s\n',absfileloc);
                return;
            end
            objExcel = actxserver('Excel.Application');
            objExcel.Workbooks.Open(absfileloc);
            for d=1:3
                dname = ['Sheet' num2str(d)];
                if(any(strcmp(sheets,dname)))
                    objExcel.ActiveWorkbook.Worksheets.Item(dname).Delete;
                end 
            end
            objExcel.ActiveWorkbook.Save;
            objExcel.ActiveWorkbook.Close;
            objExcel.Quit;
            objExcel.delete;
        end
        
        function r = driveroot()
            % just gives back the root of the current drive e.g 'Q:\\'
            p = mfilename('fullpath');
            drive = regexprep(p,':.*','');
            r = [drive ':\\'];
        end
        
        function [r,s] = subjects()
            % prompts for selection of subject folders after
            % a common parent foder has been selected. returns a cell array
            % of subject folders and the chosen parent
            r = uigetdir(syshelpers.driveroot(),'Parent Directory for Subjects');
            pool = syshelpers.subdirs(r);
            sel = listdlg('ListString',pool,'PromptString','Select Subject to Include');
            s = pool(sel);
        end

        function dirs = subdirs(folder,pattern,dofiles)
            % returns a flat list of subdirs matching 'pattern'
            % if dofile exists and evaluate to true, return a list files
            % matching 'pattern'
            d = dir(folder);
            isub = [d(:).isdir];
            if nargin == 3 && dofiles
                isub = ~isub;
            end
            dirnames = {d(isub).name};
            if nargin == 1    
                dirs = dirnames(3:end);
            else
                dirs = regexpi(dirnames,pattern,'match');
                dirs = dirs(~cellfun('isempty',dirs));
            end
        end
        
        function dirs = sdfdirs(subject_folder)
            % returns a list (cell array) of subdirectories
            % where data for SDF analysis is expected
            prepost = syshelpers.subdirs(subject_folder,'.*(pre|post).*');
            dirs = {};
            for prp = prepost
                prpr = prp{:}{:};
                diffu = syshelpers.subdirs(fullfile(subject_folder,prpr),'.*diffusion.*');
                for suspect=diffu
                    sus = fullfile(subject_folder,prpr,suspect{:}{:});
                    ds = syshelpers.subdirs(sus,'(EC|EO)');
                    ds = cellfun(@(f)fullfile(sus,f),ds,'UniformOutput',false);
                    dirs = [dirs ds]; %#ok<AGROW>
                end
            end
        end
            
        
        function conds = conditiondirs(folder,acc)
            % recursively identifies directories containing the txt files
            % with the data that this script consolidates
            targetfiles = {'stepTime.txt','sdfoutput','range.txt'};
            d = dir(folder);
            subs = extractfield(d,'name');
            for s=3:length(subs) % 1,2 are '.' , '..'
                if any(strcmp(targetfiles,subs{s}))
                    if ~any(strcmp(acc,folder))
                        [~,condname] = fileparts(folder);
                        acc(size(acc,1)+1,:) = {condname,folder,subs{s}};
                    end
                elseif d(s).isdir 
                    acc = syshelpers.conditiondirs(fullfile(folder,subs{s}),acc);
                end
            end  
            conds = acc;
        end


    end
    
end

