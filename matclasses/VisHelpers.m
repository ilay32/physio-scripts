classdef VisHelpers
    %VISHELPERS A set of helper functions for visualization of symmetries
    properties
        basedata
        basename
        numstages
        titlesprefix
        baselines
        stagenames
        model
        fitmodel
    end
    
    methods (Static)
        function [ticks,labels] = minutes(sequence,frate)
            ticks = 0:6*frate:length(sequence);
            labels = string((0:1:numel(ticks))/10);
            labels(mod(0:length(labels)-1,5) ~= 0) = ' ';
        end
        function s = symmetries(pairs)
            % expects aligned L/R columns, returns symmetry column
            s = ((pairs(:,1) - pairs(:,2)) ./ (pairs(:,1) + pairs(:,2)));
        end
        function m = remove_nan_rows(a)
            if size(a,2) > 1
                m = a(~any(isnan(a')),:);
            else
                m = a(~isnan(a));
            end
        end
    end
    
    methods
        function self = VisHelpers(specs)
            %VISHELPER Construct an instance of this class
            %   given a struct that includes the left/right data and some
            %   strings for its presentation, this class provides some
            %   methods that helps visualize it. the data itself is a cell array of
            %   different stages in the experiment. every cell holds one
            %   [ L R ] matrix.
            self.basename = specs.name;
            self.basedata = cellfun(@VisHelpers.remove_nan_rows,specs.data,'UniformOutput',false);
            self.numstages = length(specs.stagenames);
            self.stagenames = specs.stagenames;
            self.titlesprefix = specs.titlesprefix;
            self.baselines = specs.baselines;
            self.model = specs.model;
            self.fitmodel = specs.fitmodel;
        end
        
        function plot_symmetries(self,stage_index)       
            self.symplot(self.basedata{stage_index},self.titlesprefix,self.stagenames{stage_index});
        end
        
        function plot_global(self,block)
            % this function plots the symmetries of all the stages,
            % fits the given model to the stages that are listed in
            % fitmodel, and returns a struct with a cell array of
            % symmetries and the baseline symmetry value. this data can be
            % saved by the wrapping script so as to facilitate
            % cross-subject operations.
            b = [];
            
            % this class can also be instantiated with ready symmetries
            % instead of left/right data
            israw = size(self.basedata{1,1},2) == 2;
            
            % get the baseline
            for s=self.baselines
                addtobaseline = self.basedata{s};
                if israw
                    addtobaseline = VisHelpers.symmetries(addtobaseline);
                end
                b = [b;addtobaseline];
            end
            baseline = mean(b);
            figure('name',self.titlesprefix);
            hold on;
            grid on;
            cur = 1;
            psyms = {};
            for s = 1:self.numstages
                d = self.basedata{s};
                if israw
                    stagesymms = VisHelpers.symmetries(d);
                else
                    stagesymms = d;
                end
                %stagesymms = stagesymms - baseline;
                pltrange = (cur:cur+length(stagesymms)-1);    
                psyms{s} = plot(pltrange,stagesymms);
                                    
                title([strrep(self.basename,'_',' ') ' symmetry']);
            
                ylabel('symmetry');
                ylim([-1,1]);
                if ismember(s,self.fitmodel)
                    x = 1:length(stagesymms);
                    fprintf('\n\ndouble exponential model results for %s:',self.stagenames{s});
                    mfit = fit(x',stagesymms,self.model) %#ok<NOPRT>
                    pmod = plot(pltrange,mfit(x),'color','red');
                end
                cur = pltrange(end) + 1;
            end
            pbase = line([1,pltrange(end)],[baseline,baseline],'color','green');
            
            lh(1) = psyms{:};
            lh(2) = pmod;
            lh(3) = pbase;
            legend(lh,{'symmetry','model fit','baseline mean'});
            if block
                uicontrol('String','Continue','Callback','uiresume(gcbf)');
                uiwait(gcf);
            end
            hold off
        end
    end
    
    methods (Access='private',Hidden=true)
        function  symplot(self,pairs,figurename,axtitle)
            % plots symmetries of some, presumably matching, left/right data with or without
            % the diff values of the data according to the boolean
            % 'plotbase' parameter
            figure('name',figurename);
            subplot(2,1,1);
            x = (1:length(pairs));
            y = self.symmetries(pairs);
            if size(y,1) > size(y,2)
                y = y';
            end
            symsd = std(y);

            fill([x,fliplr(x)],[y + symsd,fliplr(y - symsd)],[0.75,0.75,0.75],'LineStyle','none');
            hold on;
            title(axtitle);
  
            plot(x,mean(y)*ones(1,size(x,2)));
            plot(x,y);
            ylabel('symmetry');
            ylim([-1,1]);
            legend('1 SD','mean','symmetry');
            hold off;            
            
            subplot(2,1,2);
            scatter(1:size(pairs,1),pairs(:,1),'filled');
            ylabel(self.basename);
            ylim([0,1]);
            hold on;
            scatter(1:size(pairs,1),pairs(:,2),'filled');
            legend({'right','left'});
            xlabel('step no.');
          
            hold off;
        end
    end
end

