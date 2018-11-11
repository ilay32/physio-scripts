classdef VisHelpers
    %VISHELPERS A set of helper functions for visualization of symmetries
    properties(Constant)
        straightening_ratio_criterion = 0.1;
    end
    properties
        stages
        numstages
        basename
        titlesprefix
        baselines
        model
        global_outliers_remove
    end
    
    methods (Static)
        function stages = initialize_stages(nstages)
            for s = 1:nstages
                stages(s) = struct(...
                    'faster', 'none',...
                    'step_lengths',[],...
                    'data',[],...
                    'speeds', struct('left',1,'right',1),...
                    'normalize', false,...
                    'include_inbaseline',false,...
                    'fit_curve',false,...
                    'name','',...
                    'gait_indices',struct('left',[],'right',[])...
                );
            end
        end
        function t = determine_learning_time(curve,maxslope)
            % given found parameters of an (bi)exponential
            % model, determines if the curve flattens out, and if so, when
            % -- as an index in the given range
            t = -1;
            
            % find where the derivative first drops below 
            %dvals = abs(double(d(r)));
            dvals = abs(diff(curve));
            first_dsmall = find(dvals < maxslope,1);
            
            % if it does and stays there, return the found index
            if ~isempty(first_dsmall)&& max(dvals(first_dsmall:end)) < maxslope
                t = first_dsmall;
            end
        end
        function optresults = learncurve(stage,model)
            assert(any(strcmp(stage.faster,{'left','right'})),'please specify which belt moved faster');
            ls = stage.speeds.left;
            rs = stage.speeds.right;
            repname = strrep(stage.name,'_',' ');
            F = max([ls,rs])/min([ls,rs]); % ratio between treadmill belt speeds
            if ls > rs && strcmp(stage.faster,'right')
                F = -1*F;
            end
            yNoise = stage.data;
            S = size(yNoise);
            curve = zeros(S);
            summ = '';
            function MSE = single_rate(initial)
                %iterative implementation of a single error decay theory
                %   This is an adaptation of Firas Mawasef's optimization function
                D = initial(1);
                B = initial(2);
                [zEst,yEst] = deal(zeros(S));  
                for n=1:max(S)
                    %Calculating the error
                    yEst(n)=D*F - zEst(n);
                    %Updating the internal model of the current target
                    zEst(n+1) = zEst(n)+B*yEst(n);
                end
                curve = yEst;
                MSE = sum((yEst - yNoise).^2);
            end
            
            function MSE = dual_rate(initial)
                %iterative implementation of a fast/slow learning theory
                %   This is what i gather should be the dual version
                Af = initial(1);
                Bf = initial(2);
                As = initial(3);
                Bs = initial(4);
                [zEst,zEst_Slow,zEst_Fast,yEst] = deal(zeros(S));
                for n=1:max(S)
                    yEst(n)= F - zEst(n);
                    zEst_Slow(n+1)=As*zEst_Slow(n)+Bs*(yEst(n));
                    zEst_Fast(n+1)=Af*zEst_Fast(n)+Bf*(yEst(n));
                    zEst(n+1)=zEst_Slow(n+1)+ zEst_Fast(n+1);
                end
                curve = yEst;
                MSE = sumsqr(yEst - yNoise); 
            end                       
            if regexp(model,'exp\d')
                x = 1:max(S);
                [mfit,goodness,~,comment] = fit(x',yNoise,model,'Lower',-1,'Upper',0);
                summ = sprintf('a:%f\nb:%f',mfit.a,mfit.b);
                optresults.params = struct('a',mfit.a,'b',mfit.b);
                if strcmp(model,'exp2')
                    summ = [summ sprintf('\nc:%f\nd:%f',mfit.c,mfit.d)];
                    optresults.params.c = mfit.c;
                    optresults.params.d = mfit.d;
                end
                if any(size(comment)> 0)
                    disp(comment);
                end
                %fitdata = [fitdata,dadd];
                curve = mfit(x);
                ar2 = goodness.adjrsquare;
            else
                p = 2;
                if strcmp(model,'single')
                    [params,~] = fmincon(@single_rate,[1,0],[],[],[],[],zeros(2,1),ones(2,1));
                    optresults.params = struct('B',params(1),'D',params(2));
                    summ = sprintf('B: %f\nD: %f',params);
                elseif strcmp(model,'dual')
                    [params,~] = fmincon(@dual_rate,[1,0,1,0],[],[],[],[],zeros(4,1),ones(4,1));
                    optresults.params = struct(...
                        'Af',params(1),...
                        'Bf',params(2),...
                        'As',params(3),...
                        'Bs',params(4)...
                    );
                    summ = sprintf('Af: %f\nBf: %f\nAs: %f\nBs: %f',params);
                    p = 4;
                end
                ar2 = 1 - (sumsqr(curve - yNoise)/(max(S) - p))/var(yNoise);
            end
            optresults.ar2 = ar2;
            optresults.summary = sprintf('%s:\n%s\nr^2: %f',repname,summ,ar2);
            optresults.curve = curve;
        end 
        function [ticks,labels] = minutes(sequence,frate)
            % marks a time series axis with minute ticks
            % according to the given datarate
            ticks = 0:6*frate:length(sequence);
            labels = string((0:1:numel(ticks))/10);
            labels(mod(0:length(labels)-1,5) ~= 0) = ' ';
        end
        function s = symmetries(left,right,faster_side,remove_outliers,normalize)
            % expects positive left and right vectors of same size
            % side tells which to subtract from which
            % remove outliers speaks for itself
            if any([left,right] <0)
                warning('symmetries expects non-negative values');
            end
            diffs = left - right;
            if strcmp(faster_side,'left')
                diffs = -1*diffs;
            end
            s = diffs ./ (left + right);
            if remove_outliers
                s = s(~isoutlier(s));
            end
            if normalize
                s = s/abs(mean(s(1:3)));
            end
        end
        
        function m = remove_nan_rows(a)
            if size(a,2) > 1
                m = a(~any(isnan(a')),:);
            else
                m = a(~isnan(a));
            end
        end
        
        function minutize_axes(axl,datarate)
            axes(gca);
            xlabel('minutes');
            [t,l] = VisHelpers.minutes(1:axl,datarate);
            xticks(t);
            xticklabels(l);
        end
    end
    
    methods
        function self = VisHelpers(specs)
            %VISHELPER Construct an instance of this class
            %   given a struct that includes the left/right data and some
            %   strings for its presentation, this class provides some
            %   methods that helps visualize it.
            self.basename = specs.name;
            self.numstages = length(specs.stages);
            self.global_outliers_remove = specs.remove_outliers;
            stages = specs.stages;
            for s=1:self.numstages
                if ~isempty(stages(s).step_lengths)
                    d  = stages(s).step_lengths;
                    assert(size(d,1) > 2 && size(d,2) == 2,'expecting [ left right ] columns of length 3 at least');
                    stages(s).pairs = d;
                    stages(s).data = VisHelpers.symmetries(d(:,1),d(:,2),...
                        stages(s).faster,self.global_outliers_remove,...
                        stages(s).normalize...
                    );
                else
                    d = stages(s).data;
                    assert(size(d,1) > 2 && size(d,2) == 1,'expecting 1 column of length 3 or more');
                end
            end
            self.stages = stages;
            self.titlesprefix = specs.titlesprefix;
            self.model = specs.model;
        end       
        
        function ltimes = plot_global(self,block)
            % this function plots the symmetries of all the stages,
            % fits the given model to the stages that are listed in
            % fitmodel, and returns a struct with a cell array of
            % symmetries and the baseline symmetry value. this data can be
            % saved by the wrapping script so as to facilitate
            % cross-subject operations.
            b = [];
            ltimes = struct;
            fitdata = {};
            
            % get the baseline
            for s=1:self.numstages
                stage = self.stages(s);
                if ~stage.include_inbaseline
                    continue;
                end
                a = stage.data;
                b = [b;a];
                b = b(~isoutlier(b));
            end
            baseline = mean(b);
            figure('name',self.titlesprefix);
            hold on;
            grid on;
            cur = 1;
            psyms = {};
            for s = 1:self.numstages
                stage = self.stages(s);
                %stagesymms = stagesymms - baseline;
                pltrange = (cur:cur+length(stage.data)-1);    
                psyms{s} = plot(pltrange,stage.data);
                title([strrep(self.basename,'_',' ') ' symmetry']);            
                ylabel('symmetry');
                ylim([-5,5]);
                if stage.fit_curve
                    fitresults = VisHelpers.learncurve(stage,self.model);
                    pmod = plot(pltrange,fitresults.curve,'color','red');
                    % compute the maximal slope of the graph
                    [ma,mand] = max(stage.data);
                    [mi,mind] = min(stage.data);
                    maxslope = (ma - mi)/abs(mand - mind);
                    ltime = VisHelpers.determine_learning_time(fitresults.curve,maxslope*VisHelpers.straightening_ratio_criterion);
                    line([pltrange(1)+ltime,pltrange(1)+ltime],ylim);
                    snameclean = regexprep(stage.name,'[\-\s]','_');
                    ltimes.(snameclean).split = ltime;
                    ltimes.(snameclean).quality = fitresults.ar2;
                    ltimes.(snameclean).params = fitresults.params;
                    ltimes.(snameclean).mf5 = mean(stage.data(1:5));
                    ltimes.(snameclean).ml30 = mean(stage.data(end-30:end));
                    ltimes.(snameclean).ml5 = mean(stage.data(end-5:end));
                    fitdata = [fitdata,fitresults.summary];
                end
                cur = pltrange(end) + 1;
            end
            pbase = line([1,pltrange(end)],[baseline,baseline],'color','green');
            
            lh(1) = psyms{:};
            lh(2) = pmod;
            lh(3) = pbase;
            legend(lh,{'symmetry','model fit','baseline mean'});
            loc = [0.15,0.15];
            boxsize = [0.1,0.2];
            for s=1:length(fitdata)
                if s==2
                    loc = loc + [boxsize(1)+0.05,0];
                end
                annotation('textbox',[loc,boxsize],'String',fitdata{s},'FitBoxToText','on');
            end
            if block
                uicontrol('String','Continue','Callback','uiresume(gcbf)');
                uiwait(gcf);
            end
            hold off
        end
   
        function  plot_symmetries(self,stage_index)
            % plots symmetries of some, presumably matching, left/right data with or without
            % the diff values of the data according to the boolean
            % 'plotbase' parameter
            figure('name',self.titlesprefix);
            subplot(2,1,1);
            stage = self.stages(stage_index);
            y = stage.data';
            x = 1:size(y,2);
            symsd = std(y);
            fill([x,fliplr(x)],[y + symsd,fliplr(y - symsd)],[0.75,0.75,0.75],'LineStyle','none');
            hold on;
            title(stage.name);
            plot(x,mean(y)*ones(1,size(x,2)));
            plot(x,y);
            ylabel('symmetry');
            ylim([-5,5]);
            legend('1 SD','mean','symmetry');
            hold off;            
           
            subplot(2,1,2);
            scatter(1:size(stage.pairs,1),stage.pairs(:,1),'filled');
            ylabel(self.basename);
            ylim([0,1]);
            hold on;
            scatter(1:size(stage.pairs,1),stage.pairs(:,2),'filled');
            legend({'right','left'});
            xlabel('step no.');          
            hold off;
        end
    end
end

