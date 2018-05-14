function [timings] = StepTimes(start,finish,COPY,Fz)
    % this function takes cleaned COP data from one plate and a global index range
    % and returns step lengths along with their global indices. 
    % Every row represents a step: [ start(ind) length(meters) end(ind) ]
    % start: int starting index for steps
    % finish: int final index for steps
    % COPY: COP data from forceplate along Y axis
    lookahead = 10;
    lookbehind = 10;
    thresh = 0.2; % 20cm away from Y = 0
    cur = start - lookbehind;
    steps = 0;
    proportion = 0.3;
    weight = mean(findpeaks(Fz,'MinPeakDistance',100))/2; %very simplistically
    assert(weight > 300, 'subject is too light ~ 30kg');
    assert(weight < 2000, 'subject is too heavy ~ 200kg');
    halfweight = proportion * weight;
    while cur <= finish
        % heel strike is the first numeric value in step
        while isnan(COPY(cur)) | COPY(cur) < thresh
            cur = cur + 1;
        end
        % found the HS so step starts when force on the plate is at least halfweight
        while Fz(cur) < halfweight
            cur = cur + 1;
        end
        
        step_start = cur;
        
        % scan a lookahead window for all NaN or very small
        step_end = 0;
        while step_end == 0 & cur + lookahead <= finish
            % reset the end index each time. see comment below.
            step_end = 0;
            forward = COPY(cur:cur+lookahead);
            if all(isnan(forward) | forward < thresh) | all(Fz(cur:cur+lookahead) < halfweight)
                step_end = cur-1;
            elseif cur  > finish - lookahead
                disp(forward);
                step_end = min(finish,cur + lookahead);
            end
            cur = cur + 1;
        end
        
        % if step_end = 0 it means the stage finish mark is in the middle
        % of a step on this plate
        if step_end  > step_start
            steps = steps + 1;
            step = COPY(step_start:step_end);
            [~,mxind] = max(step);
            [~,mnind] = min(step);
            if max(step) > min(step)
                timings(steps,:) = [step_start + mxind,step_start + mnind]; % HS TO
            else
                disp(step);
            end
        end
        cur = cur + 1;
    end
end