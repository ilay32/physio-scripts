classdef RestepGroups < GaitForsGroups
    %RESTEPGROUPS aggregates ReStep experiment data
    %   assumes treadmill outputs from AnalyzeRestep.m
    %   given a query e.g 'cva & pre', returns the aggregated data 
    properties(Constant)
        export_basics = {'step_length'}
    end
    methods
        function self = RestepGroups(rootfolder)
            %RESTEPGROUPS Implement the ReStep version of GaitForsGroups
            self@GaitForsGroups(rootfolder);
            confs = yaml.ReadYaml('conf.yml');
            self.conf = confs.GaitFors.restep;
            self.groups = {
                {'CVA','TBI','both_impairments'};...
                {'pre','post','both_sessions'}...
            };
            self.data_names = {'time1','steps1','meansym_last30','meansym1','meansym2','meansym_first5','meantotal'}; 
        end
        
        function p = agg_dirs(self,agg1,agg2)
            agg1folder = agg1;
            if startsWith(agg1,'both')
                agg1folder = '*';
            end
            if startsWith(agg2,'both')
                agg2folder = '*';
            else
                if strcmp(agg2,'pre')
                    agg2folder = 'Day1';
                else
                    agg2folder = 'Day2';
                end
            end
            pat = fullfile(self.datafolder,agg1folder,'*',agg2folder,'*gist.mat'); % the wildcard is the subject ID
            p = dir(pat);
        end
        
        function b = is_baseline_stage(self,s,n1,n2)  %#ok<INUSL,INUSD>
            b = s == 2;
        end
        
        function regenerate_gists(self)
            pat = fullfile(self.datafolder,'*','*','*','*gist.mat'); 
            % the wildcards are: cva/tbi, subjid, day<x>
            gistfiles = dir(pat);
            for g = 1:length(gistfiles)
                folder = gistfiles(g).folder;
                listofcop = syshelpers.subdirs(folder,'.*COP.*txt',true);
                if isempty(listofcop)
                    gf = GaitMissing(folder,'restep');
                    gf = gf.load_from_disk();
                else
                    gf = GaitForceEvents(folder,'restep');
                    gf = gf.load_stages();
                end
                gf = gf.compute_basics();
                
                for b=self.conf.constants.basicnames
                    fprintf('Computing %s Symmetries:\n',b{:});
                    visu = gf.get_visualizer(b{:});
                    learning_times = visu.plot_global(false);
                    gf = gf.process_learning_times(learning_times,b{:});
                    fprintf('done.\n\n');
                    close all;
                end
                gf.save_gist();
            end
        end
    end
end

