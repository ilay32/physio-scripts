function [matched_lengths] = AlignSteps(stage,rcop,lcop,start)
    % the stage of each side are assumed to be valid -- times are
    % correctly ordered: hs1 < to1 < hs2 < to2 ...
    % stage: 1 x [ RIGHT LEFT ] cell array. 
    % R and L are [ No. Steps ] x [ HS-INDEX LENGTH TO-INDEX] matrices.
    m = 1;
    rcur = start;
    lcur = start;
    left = stage{:,2};
    right = stage{:,1};
    
    % recursion stop
    if start > size(left,1) | start > size(right,1)
        matched_lengths = double.empty(0,2);
        return;
    end
    
    % find where to start
    while right(rcur,1) <= left(lcur,2)
        rcur = rcur + 1;
        % make sure we don't run of data at this stage too
        if rcur >= size(left,1) | rcur >= size(right,1)
            matched_lengths = double.empty(0,2);
            return;
        end
   end
    
    % find the closest lto after the found right heel strike
    while left(lcur,2) <= right(rcur,1)
        lcur = lcur + 1;
    end
    
    % starting at 'cur', cycle through the hs/to data seeking the nearest appropriate entry
    % every time: RHS -> LTO -> LHS -> RTO -> RHS each one must be
    % larger than previous but no larger than next. Stop when end of
    % shorter side is reached.
    % HS in same row. if a mismatch is encountered, register the bad index
    % and recurse starting from the bad.
    while lcur < size(left,1) & rcur < size(right,1)
        rhs = right(rcur,1);
        lto = left(lcur,2);
        lhs = left(lcur + 1,1);
        rto = right(rcur,2);
        if all(abs([rto - lhs,lto - rhs])<50) & rhs < lhs & lto < rto % rule of thumb: allow for small difference between consecutive hs and to, require strict ordering of rto-lto,rhs-lhs 
            matched_lengths(m,:) = [lcop(lhs) - rcop(rto),rcop(rhs) - lcop(lto)];
            m = m + 1;
        else
            fprintf('\nproblem at %d left -- %d right:\nRTO: %d\tLHS: %d\tLTO: %d\tRHS: %d',...
                lcur,rcur,rto,lhs,lto,rhs...
            );
            if exist('matched_lengths','var')
                matched_lengths = [matched_lengths;AlignSteps(stage,rcop,lcop,max(rcur,lcur))];
            else
                matched_lengths = AlignSteps(stage,rcop,lcop,max(rcur,lcur));
            end
            break;
        end
        rcur = rcur + 1;
        lcur = lcur + 1;
    end
end   