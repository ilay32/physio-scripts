classdef SaluteGroups < GaitForsGroups
    %RESTEPGROUPS aggregates ReStep experiment data
    %   assumes treadmill outputs from AnalyzeRestep.m
    %   given a query e.g 'post', returns the aggregated data
    properties(Constant)
        export_basics = {'ds_duration'};
    end
    methods
        function self = SaluteGroups(rootfolder)
            %RESTEPGROUPS Implement the ReStep version of GaitForsGroups
            self@GaitForsGroups(rootfolder);
            confs = yaml.ReadYaml('conf.yml');
            self.conf = confs.GaitFors.salute;
            self.groups = {
                {'all'};...
                {'pre','post','both_sessions'}...
            };
            self.data_names = GaitForceEvents.lrows; 
        end
        
        function p = agg_dirs(self,agg1,agg2) %#ok<INUSL>
            if startsWith(agg2,'both')
                agg2 = '*';
            end
            pat = fullfile(self.datafolder,'*','treadmill',agg2,'*gist.mat'); % the wildcard is the subject ID
            p = dir(pat);
            if isempty(p)
                pat = fullfile(self.datafolder,'*','treadmill',agg2,'part1','*gist.mat'); % split cases
                p = dir(pat);
            end
        end
        
        function namescell = get_stage_names(self,gistpath,groupcriterion1,groupcriterion2) %#ok<INUSL>
            if ~strcmp(groupcriterion2,'both_sessions')
                namescell = self.conf.constants.stagenames.(groupcriterion2);
            else
                if regexpi(gistpath,'post','ONCE')
                    key = 'post';
                elseif regexpi(gistpath,'pre','ONCE')
                    key = 'pre';
                else
                    error('gist file location is not pre nor post. please sort it out');
                end
                namescell = self.conf.constants.stagenames.(key);
            end
        end
    end
end