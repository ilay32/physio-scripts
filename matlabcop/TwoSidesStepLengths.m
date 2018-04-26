function [lengths] = StepLengths(GEInd,COPY,ix)
    % This function takes a vector of gait event indices
    % and a matrix of Y axis COP (left and right), and returns
    % a matrix listing the step lengths with the resulting symmetry value. 
    % ix: 2(k-1) long list of stage initiation-termination indices 
    % GEInd: gait event indices [ k stages ] x [ RIGHT  LEFT ] relative to
    % stage
    % COPY: the Y axis [ RIGHT LEFT ] values on the same stretch of data
    close all;
    assert(size(ix,2)/2 == size(GEInd,1) -1,'Trial Stages Don"t match');
    for i=1:size(GEInd,1)
        stage = COPY(ix(i):ix(i+1))';
        stageindsr = GEInd{i,1};
        stageindsl = GEInd{i,2};
        stage_lengths = zeros(min(size(stageindsr,1),size(stageindsl,1)),2);
        % start with the first right heel strike that's later than the
        % first left toe off
        rcur = 1;
        while stageindsr(rcur,1) <= stageindsl(1,2)
            rcur = rcur + 1;
        end
        lcur = 1;
        % find first lto
        while stageindsl(lcur,2) <= stageindsr(rcur,1)
            lcur = lcur + 1;
        end
        % starting at 'cur', cycle through the hs/to data seeking the nearest appropriate entry
        % every time: RHS -> LTO -> LHS -> RTO -> RHS each one must be
        % larger than previous but no larger than next. Stop when end of
        % shorter part is reached. for now, assuming that at every index,
        % the TO entry is later than the HS one.
        while lcur < length(stageindsl) & rcur < length(stageindsr)
            prevlhs = stageindsr(lcur,1);
            rhs = stageindsr(rcur,1);
            lto = stageindsl(lcur,2);
            lhs = stageindsl(lcur + 1,1);
            rto = stageindsr(rcur,2);
            disp(stage(prevlhs,:));
            disp(stage(rhs,:));
            disp(stage(lto,:));
            disp(stage(rto,:));
            % if it's all good do the symmetry
            if rto > lhs & lhs > lto & lto > rhs & rhs > prevlhs
                stage_lengths(rcur,1) = stage(rhs,1) - stage(rto,1);
                stage_lengths(rcur,2) = stage(prevlhs,2) - stage(lto,2);
            else
                disp('something is awefully wrong');
            end
            rcur = rcur + 1;
            lcur = lcur + 1;
        end 
        lengths{i} = stage_lengths;
    end
end