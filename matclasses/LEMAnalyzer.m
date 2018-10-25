classdef LEMAnalyzer
    % a set of functions to process
    % data collected from LEMOCOT test on Ind. Eng. Lab forceplate.
    properties (Constant)
        % this was measured by several trials of putting some object
        % on the two dotts marked on the forceplate
        centerx = 0.1526;
        aoffst = -0.042; % half the forceplate thickness in meters. taken from it's software interface.
        denoise_bins = 100; % quite arbitrary 50 would also do. for usage see 'findnoise'
        denoise_mincount = 5; % not so arbitrary. see 'findnoise'.
        epsi = eps;
        touchspan = 50; % also arbitrary, the number of readings to take from both sides of an identified touch index
        datarate = 300 % Hz, since the csv exports contain only the raw readings, this rate is assumed and not computed
        accuracy = 0.04; % radius of accuracy for the valid touch decision -- 4 cm
        first_touch_scan_window=100;
        lemduration = 20; % 20 seconds of test.
        multcolors = {'red','green','blue'};
    end
    properties
        data
        buttera
        butterb
        nears
        fars
        centers
        zeronoise
        lemstart
        weakmy
        subjid
        part
        datfolder
        filebase
        extension
        touch_points
        tare_points
    end
    methods (Static)
        function noisedat =  findnoise(sample)
            % analyze values distribution in given 1d vector
            % typically, the frequent value is considered the actual one
            % the rest are "noise"
            eps = LEMAnalyzer.epsi;
            ma = max(sample);
            mi = min(sample);
            noise = struct('bins','mincount','vals',[],'epsilons',[],'level',0,'princval',0);
            edges = mi - eps:((ma - mi)/LEMAnalyzer.denoise_bins):ma+eps;
            [n,x] = histc(sample,edges);
            frequents = find(n > LEMAnalyzer.denoise_mincount);
            [~,mfind] = max(n);
            pv = mean(sample(x == x(mfind))); % most frequent value in given sample mean for safety
            % register the other values
            frequents = frequents(frequents ~= mfind);
            for i=1:length(frequents)
                subj = sample(x==frequents(i));
                m = mean(subj);
                e = abs(max(subj - m));
                noise.vals(i) = m;
                noise.epsilons(i) = e;
            end
            anoises = abs(noise.vals - pv);
            [~,amaxind] = max(anoises);
            noise.maximal.val = noise.vals(amaxind); % how far is the farthest value from the principal one
            noise.maximal.eps = noise.epsilons(amaxind);
            
            [~,aminind] = min(anoises);
            noise.minimal.val = noise.vals(aminind); % smallest noise
            noise.minimal.eps = noise.epsilons(aminind);
            noise.princval = pv;
            noisedat = noise;
        end
        function cleaned = eliminate_noises(dat,noise,reduceto)
            % given a noise object and a desired value,
            % convert all noise values to the desired one
            % is member wouldn't work here since we want +- epsilon hits
            % too
            for i = 1:length(noise.vals)
                e = noise.epsilons(i);
                v = noise.vals(i);
                dat(dat >= v - e & dat <= v + e) = reduceto;
            end
            cleaned = dat;
        end
        function [cleaned] = clean(d,reduceto)
            % finds the noise in d
            % and puts everything on the principal value
            cleaned = zeros(size(d));
            for i=1:size(d,2)
                n = findnoise(d(:,i));
                if nargin == 1
                    reduceto = n.princval;
                end
                cleaned(:,i) = reduce(d(:,i),n,reduceto);
            end
        end
        function [copx,copy] = staticops(d,stretch)
            % this was used to find the centers
            % assumes an inanimate motionless object on the plate
            % returns the mean "raw COP" coordinates of the object location
            c  = clean(d(stretch,3:5));
            fz = c(:,1);
            mx = c(:,2);
            my = c(:,3);
            copx = (-1 * my) / mean(fz);
            copy = mx / mean(fz);
        end
    end
    
    methods
        function self = LEMAnalyzer(lemfile)
            % data is fx fy fz mx my mz in CSV
            self.data = load(lemfile);
            [self.butterb,self.buttera] = butter(1,0.02); % by some trial and error on test data
            cx = LEMAnalyzer.centerx;
            self.centers.near = [-1*cx,0];
            self.centers.far = [cx,0];
            [p,b,e] = fileparts(lemfile);
            [~,t] = regexp(b,'(\w+)LEM(\d).*','match','tokens');
            self.datfolder = p;
            self.filebase = b;
            self.extension = e;
            tok = t{1,1};
            if all(size(tok) == [1,2])
                self.subjid = tok{1,1};
                self.part = tok{1,2};
            else
                self.subjid = 'unknown';
                self.part = '0';
            end
        end
        
        function showtouches_multiple(self)
            pspecs = {
                {'near', 'o'},...
                {'far','^'},...
                {'out','x'}
            };
            others = self.find_others();
            if isempty(others)
                self.showtouches_single();
                return;
            end
            self.init_points_plot();
            allfiles = [{self},others];
            labels = cell(1,length(allfiles));
            title([self.subjid ' All LEMOCOT Reslts']); 
            lh = [];
            for inst=1:length(allfiles)
                if inst>1
                    lma = LEMAnalyzer(allfiles{inst});
                else
                    lma = self;
                end
                lma = lma.tare();
                lma = lma.identify();
                lma = lma.validate_touches('raw');
                color = LEMAnalyzer.multcolors{inst};
                % matlab's stupid way of making an arbitrary legend entry
                lh(inst) = plot(NaN,NaN,'s','MarkerFaceColor',color,'MarkerEdgeColor',color);
                labels{inst} = sprintf('part %s',lma.part);
                for spec=1:3
                    pspec = pspecs{spec};
                    copxy = lma.touch_points.(pspec{1});
                    plts = cell(1,size(copxy,1));
                    for i = 1:size(copxy,1)
                        plts{i} = plot(copxy(i,1),copxy(i,2),pspec{2},'MarkerFaceColor',color,'MarkerEdgeColor',color);
                    end
                end
                lma.summary_row();
                if inst>1
                    clear lma
                end
            end
            legend(lh,labels)
            hold off;
        end
        
        function init_points_plot(self)
            % plot the centers and the required accuracy circle
            figure;
            hold on;
            grid on;
            ylim([-0.15,0.15]);
            xlim([-0.25,0.25]);
            radius = LEMAnalyzer.accuracy;
            for c={'near','far'}
                center = self.centers.(c{:});
                plot(center(1),center(2),'+','color','black','MarkerSize',20);
                th = 0:pi/50:2*pi;
                xs = radius * cos(th) + center(1);
                ys = radius * sin(th) + center(2);
                plot(xs,ys,'color','black');
            end
        end
        function showtouches_single(self)
            self = self.validate_touches('raw');
            self.init_points_plot();
            title([self.subjid ' LEMOCOT No. ' self.part]);          
            pspecs = {
                {'near','b*'},...
                {'far','g*'},...
                {'out','rx'}...
            };
            for spec=1:3
                pspec = pspecs{spec};
                copxy = self.touch_points.(pspec{1});
                plts = cell(1,size(copxy,1));
                for i = 1:size(copxy,1)
                    plts{i} = plot(copxy(i,1),copxy(i,2),pspec{2});   
                end
                lh(spec) = plts{:};
            end
            legend(lh,{'near','far','out'});
            hold off;
            self.summary_row();
        end
        
        function summary_row(self)
            fprintf('subject %s part %s:\n\r counted %d touches on the near side, %d on the far side, and %d invalid\n',...
    self.subjid, self.part,length(self.touch_points.near),length(self.touch_points.far),length(self.touch_points.out));
        end
        
        function [cop,rcop] = copontouch(self,touchindices)
            % given some force peak indices,
            % returns the places on the plate in which they occurred.
            % rcop is "raw cop" -- without compensation for the force
            % directionality. cop is the traditional one as explained here:
            % https://isbweb.org/software/movanal/vaughan/kistler.pdf for exampl.
            marg = LEMAnalyzer.touchspan;
            dl = length(self.data);
            a = LEMAnalyzer.aoffst;
            numtouches = size(touchindices,1);
            cop = nan*ones(numtouches,2);
            rcop = cop;
            for i=1:numtouches
                area = self.data(max(0,touchindices(i) - marg) : min(dl,touchindices(i) + marg),:);
                area = area(abs(area(:,3)) > 0,:);
                if any(size(area) == 0)
                    warning('touch no. %d identified, but the force and/or My data around it are insufficient',...
                        i)
                    continue;
                end
                Fz = area(:,3);
                Mx = area(:,4);
                My = area(:,5);
                Fx = area(:,1);
                Fy = area(:,2);
                copx = -1 * ((My + (a * Fx)) ./ Fz);
                copy = (Mx - (a * Fy)) ./ Fz;
                rcopx = -1*My ./ Fz;
                rcopy = Mx ./ Fz;
                cop(i,:) = [mean(copx),mean(copy)];
                rcop(i,:) = [mean(rcopx),mean(rcopy)];
            end
        end   
        
        function self = tare(self)
            % identify the points where fz is supposed to be 0,
            % and set all the data columns to 0 in those points.
            fz = self.data(:,3);
            % plot raw fz of first 10 seconds,
            % the user has to mark the place after the 'tare' was pressed
            % and before the subject put their foot on the force plate.
            figure;
                plot(fz(1:10*self.datarate));
                title('mark the baseline');
                xs = round(ginput(2));
                close;
            
            n = LEMAnalyzer.findnoise(fz(min(xs):max(xs)));
            self.tare_points = [min(xs),max(xs)];
            weakindex = find((fz >= n.minimal.val - n.minimal.eps) & (fz <= n.minimal.val + n.minimal.eps));
            if ~isempty(weakindex)
                weak_mys = abs(self.data(weakindex,5));
                weak_mys = weak_mys(weak_mys > 0);
                self.weakmy = min(weak_mys);
            else
                self.weakmy = 0.1;
            end
            
            assert(n.princval == 0,'this stretch is not mostly 0. aborting.');
            fz = LEMAnalyzer.eliminate_noises(fz,n,0);
            self.data(fz == 0,:) = 0;
        end
        function others = find_others(self)
            % return a cell array with all other LEMOCOT data files 
            % pertaining to the current subject in the same directory
            others = {};
            for i=1:3
                if i ~= str2double(self.part)
                    searchfor = fullfile(self.datfolder,[self.subjid 'LEM' num2str(i) self.extension]);
                    if(exist(searchfor,'file'))
                        others = [others,{searchfor}];
                    end
                end
            end
        end
        function self = identify(self)
            % having cleaned the data,
            % try to find the leg touches on the plate
            % by Y moment (it just so happened that the dotts are spread
            % out along the X axis).
            
            % smooth the My
            my =  filtfilt(self.butterb,self.buttera,self.data(:,5));
            
            % scan for first significant drop below zero within the first
            % 20 seconds after tare start
            w = LEMAnalyzer.first_touch_scan_window;
            for i=self.tare_points(1):w:20*self.datarate
                if (mean(my(i:i+w)) < 0) && (min(my(i:i+w)) < self.weakmy*-1)
                    break;
                end
            end
            lstart = i + w;
            clear i;
            % for better peak identification we can assume 
            % that a sixth of a second between touches **on the same side**
            % is faster than anyone, and take only the identified start +
            % 25 secs. take as maximal index 20 seconds from first near
            % touch + window.
            lemrange = lstart:lstart + LEMAnalyzer.lemduration*self.datarate + 2*w;
            my = my(lemrange);
            
            % try to get a general estimate of the touch frequency, and use
            % it as minimal peak distance
            [pxx,f] = pwelch(my,[],[],[],self.datarate);
            [~,di] = max(pxx);
            pdist = self.datarate/f(di+2);
            
       
            
            % plot the my
            figure;
            plot(my);
            hold on
            
            for side = [-1,1] % mins maxs i.e far and near side of the subject respectively
                [pks,idx] = findpeaks(my*side,'MinPeakHeight',self.weakmy,...
                    'MinPeakDistance',pdist...
                );
                
                % first touch is the first negative peak
                if side == -1
                    shape = 'r*';
                else
                    shape = 'g*';
                end
                for i=1:size(idx,1)
                    plot(idx(i),pks(i)*side,shape);
                end
                % register the peaks relative to all the data
                if side == -1
                    self.fars = lstart + idx;
                else
                    self.nears = lstart + idx;
                end
            end
            ok = input('Do you approve these points? [Y/N] ','s');
            % if the user is not satifsfied, abort
            assert(strcmp(ok,'y') || strcmp(ok,'Y'),'Ok. All is lost. I retire.');
            self.lemstart = lstart;
            hold off;
            close;
        end

        function self = validate_touches(self,raw)
            % plot all the touching points
            radius = LEMAnalyzer.accuracy;
            points = struct('near',[],'far',[],'out',[]);
            copkind = 1; % classic cop
            if nargin == 2 && strcmp(raw,'raw')
                copkind = 2; % "raw"
            elseif nargin == 2
                warning('"raw" COP should be specified as "raw". using classic COP');
            end
            
            if isempty(self.nears) % or self.fars for that matter
                self = self.identify();
            end
            for side={'nears','fars'}
                cside = strip(side{:},'right','s');
                if strcmp(cside,'far')
                    oppocside = 'near';
                else
                    oppocside = 'far';
                end
                touch_inds = self.(side{:});
                [classic_cop,raw_cop] = self.copontouch(touch_inds);
                if copkind == 2
                    touch_cops = raw_cop;
                else
                    disp('classic');
                    touch_cops = classic_cop;
                end
                wrnmsg = sprintf(' was found to be near enough to the %s center,\nbut was registered as a %s touch',...
                    oppocside,cside);
                for i = 1:length(touch_cops)
                    point = touch_cops(i,:);
                    pwarnmsg = [sprintf('the point [%.3f %.3f]',point) wrnmsg];
                    dist_from_near = norm(point - self.centers.near);
                    dist_from_far  = norm(point - self.centers.far);
                    if (dist_from_near > radius) && (dist_from_far > radius)
                        points.out(i,:) = point;
                    elseif (dist_from_near <= radius) && (dist_from_far > radius)
                        points.near(i,:) = point;
                        if strcmp(cside,'far')
                            warning(pwarnmsg);
                        end
                    elseif (dist_from_near > radius) && (dist_from_far <= radius)
                        points.far(i,:) = point;
                        if strcmp(cside,'near')
                            warning(pwarnmsg);
                        end
                    else
                        warning('the point %.3f,%.3f is neither in or out of both centers. it was registerd as %s',point,cside);
                    end
                end
            end
            % clear zero
            for c = {'near','far','out'}
                ps = points.(c{:});
                if ~isempty(ps)
                    points.(c{:}) = ps(sum(ps == [0,0],2) < 2,:);
                end
            end
            self.touch_points = points;
        end
    end
end

