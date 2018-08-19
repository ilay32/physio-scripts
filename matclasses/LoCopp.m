classdef LoCopp
    %LOCOPP Summary of this class goes here
    %   Detailed explanation goes here
    properties (Constant)
        eventnames = {'HSL','TOR','MidSSL','HSR','TOL','MidSSR'};
    end 
    properties
        names
        data
        hasdata
        length
        start
    end   
    methods
        function self = LoCopp(folder)
            %LOCOPP helper class to read from GaitForces's "List of COP
            %points" file
            pointsfile = dir([folder '/*COP*.txt']);
            self.hasdata = false;
            if isempty(pointsfile)
                warning('there is no list of cop points file in the given directory');
                return;
            end
            points = importdata(fullfile(pointsfile.folder,pointsfile.name));
            if isempty(points)
                warning('the list of cop points in this folder is empty');
                return;
            end
            d = sortrows(points.data,3);
            self.data = array2table(d,'VariableNames',{'copx','copy','time'}); 
            self.hasdata = true;
            % sometimes the left column is blank
            if all(strcmp(points.textdata(:,1),''))
                n = points.textdata(:,3);
            else
                n = points.textdata(:,2);
            end
            % the gait force original only distinguishes left from right in heel strikes. this swap makes the list more informative.
            enames = LoCopp.eventnames;
            step = length(enames);
            for i=1:step
                n(i:step:end) = enames(i);
            end
            self.names = n;
            self.length = length(n);
            self.start = d(1,3);
        end
        
        function d = get_event(self,event_name,columns,range)
            % returns the sub-table corresponding to the given event
            % by the specified cell array of columns. if absent, all
            % columns are used
            assert(any(strcmp(LoCopp.eventnames,event_name)),...
                'event name must be one of: %s',strjoin(LoCopp.eventnames,','));
            if nargin > 2
                if ~iscell(columns)
                    columns = cellstr(columns);
                end
                assert(all(ismember(columns,self.data.Properties.VariableNames)),...
                    'data column must be one of: %s',strjoin(self.data.Properties.VariableNames));
            else
                columns = {};
            end
            take = strcmp(self.names,event_name); % logical array with true on the relevant indices
            % a specific time range was provided
            if nargin == 4 
                take = take & self.data.time >= range(1) & self.data.time <= range(2);
            end
            if isempty(columns)
                d = self.data(take,:);
            else
                d = self.data(take,columns);
            end
        end
    end
end

