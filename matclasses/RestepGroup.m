classdef RestepGroups
    %RESTEPGROUPS aggregates ReStep experiment data
    %   assumes treadmill outputs from AnalyzeRestep.m
    %   given a query e.g 'cva & pre', returns the aggregated data 
    properties(Constant)
        groups = {'cva','tbi','both','pre','post','all'};
        data_length = 1;
    end
    properties
        datafolder;
        keys;
    end
    
    methods
        function self = RestepGroups(rootfolder)
            %RESTEPGROUPS Construct an instance of this class
            %   just provide the root folder for the data and the required
            %   combination
            gs = RestepGroups.groups;
            self.datafolder = rootfolder;
            
        end
        
        function v = flat_averages()
            %FLAT_AVERAGES return the average values of subjects data items
            cart = meshgrid(RestepGroups.groups,RestepGroups.groups);
            for g = 1:length(cart)
                agg1 = cart{g,1};
                agg2 = cart{g,2};
                v
        end
    end
end

