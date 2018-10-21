classdef GaitMissing < GaitForceEvents
    %GAITMISSING Summary exactly like GaitForceEvents, but uses
    %self-detected HS and TO instead of the "List of COP points"
    methods
        %function self = GaitMissing(folder,stagenames,basicnames,subjectpattern)
        %    self@GaitForceEvents(folder,stagenames,basicnames,subjectpattern);
        %end

        function self = load_from_disk(self)
            svn = fullfile(self.datafolder,[self.subjid '_hsandboundaries.mat']);
            load(svn,'dat');
            self.stages = dat.stages;
            clear dat;
        end
        
        function [longest,stagedata] = compute_stage_basics(self,stageindex)
            stage = self.stages(stageindex);
            % eventually, you want a table which is easy to write to excell
            % but column lengths are not known at this point, so I just collect them to
            % a temp struct, from which i'll make the table at the end.
            stagedata = struct;
            % add the left and right columns of every base to the temp struct
            longest = 1;
            for base = self.basicnames
                for side = {'left','right'}
                    if strcmp(side{:},'left')
                        oposide = 'right';
                    else
                        oposide = 'left';
                    end
                    varname = [base{:} '_' side{:}];
                    this_hs = stage.([side{:} '_hs']);
                    that_hs = stage.([oposide '_hs']);
                    this_to = stage.([side{:} '_to']); 
                    that_to = stage.([oposide '_to']);
                    this_hs = this_hs(:,1);
                    that_hs = that_hs(:,1);
                    if strcmp(oposide,'left')
                        that_hs = that_hs(2:end);
                        this_to = this_to(2:end);
                    end
                    minhs = min(length(this_hs),length(that_hs));
                    switch base{:}
                        case 'step_length'
                            % the steps lengths are computed by copy
                            datcol  = self.forces.copy(that_to) - self.forces.copy(this_hs(1:length(that_to)));
                        case 'step_duration'
                            datcol = (this_hs(2:minhs) - that_hs(1:minhs-1))/self.datarate;
                        case 'stride_duration'
                            datcol = diff(this_hs)/self.datarate;
                        case 'stride_length'
                            continue;
                        case 'step_width'
                            datcol = abs(self.forces.copx(this_hs(1:minhs)) - self.forces.copx(that_hs(1:minhs)));
                        case 'swing_duration'
                            cur = 1;
                            while this_hs(cur) < this_to(1)
                                cur = cur + 1;
                            end
                            datcol = (this_hs(cur:cur+length(this_to)-1) - this_to)/self.datarate;
                        case 'stance_duration'
                            datcol = (this_to - this_hs(1:length(this_to)))/self.datarate;

                        case 'ds_duration'
                            datcol = (that_to - this_hs(1:length(that_to)))/self.datarate;
                    end
                    if any(datcol < 0)
                        warning('there were %d negative values out of %d',sum(datcol<0),length(datcol));
                    end
                    if length(datcol) > longest
                        longest = length(datcol);
                    end
                    if ~strcmp(base{:},'stride_length')
                        stagedata.(varname) = datcol;
                    end
                end
            end
            % now stride length by summing step lengths
            stepsl = stagedata.step_length_left;
            stepsr = stagedata.step_length_right;
            minl = min(length(stepsl),length(stepsr));
            stagedata.stride_length_left = stepsl(1:minl) + stepsr(1:minl);
            stagedata.stride_length_right = stepsl(2:minl) + stepsr(1:minl-1);
        end           
    end
end

