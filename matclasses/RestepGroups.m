classdef RestepGroups
    %RESTEPGROUPS aggregates ReStep experiment data
    %   assumes treadmill outputs from AnalyzeRestep.m
    %   given a query e.g 'cva & pre', returns the aggregated data 
    properties
        datafolder;
        groups;
        data_names;
        data_length;
        stage_names;
    end
    
    methods
        function self = RestepGroups(rootfolder,stages)
            %RESTEPGROUPS Construct an instance of this class
            %   just provide the root folder for the data and the required
            %   combination
            self.groups = {
                {'CVA','TBI','both_impairments'},...
                {'Day1','Day2','both_sessions'}...
            };
            self.stage_names = stages;
            self.data_names = {'learning_times','learning_steps'};
            self.datafolder = rootfolder;
        end
        
        function p = agg_dirs(self,agg1,agg2)
            if startsWith(agg1,'both')
                agg1 = '*';
            end
            if startsWith(agg2,'both')
                agg2 = '*';
            end
            pat = fullfile(self.datafolder,agg1,'*',agg2,'*gist.mat'); % the wildcard is the subject ID
            p = dir(pat);
        end
        
        function collected = flat_averages(self,stage)
            %FLAT_AVERAGES return the average values of subjects data items
            collected = struct;
            for g1 = 1:length(self.groups{1})
                for g2 = 1:length(self.groups{2})
                    fprintf('gathering %s / %s data\n',g1,g2)
                    dat = zeros(0,self.data_length);
                    key = lower([g1 '_' g2]);
                    gists = self.agg_dirs(self.groups{1,g1},self.groups{2,g2});
                    for d=1:length(gists)
                        dat = [dat,self.subject_data(fullfile(d.folder,d.name))];
                    end
                    collected.(key) = array2table(mean(dat),self.data_names);
                end
            end
        end
    end
end

