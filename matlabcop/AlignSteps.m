function [matched_lengths] = AlignSteps(stage,start)
    % the stage of each side are assumed to be valid -- times are
    % correctly ordered: hs1 < to1 < hs2 < to2 ...
    % stage: 1 x [ RIGHT LEFT ] cell array. 
    % R and L are [ No. Steps ] x [ HS-INDEX LENGTH TO-INDEX] matrices.
    m = 1;
    rcur = start;
    lcur = start;
    left = stage{:,2};
    right = stage{:,1};
    if start > size(left,1) | start > size(right,1)
        matched_lengths = double.empty(0,2);
        return;
    end
    while right(rcur,1) <= left(lcur,3)
        rcur = rcur + 1;
    end
    
    % find the closest lto after the found right heel strike
    while left(lcur,3) <= right(rcur,1)
        lcur = lcur + 1;
    end
    
    % starting at 'cur', cycle through the hs/to data seeking the nearest appropriate entry
    % every time: RHS -> LTO -> LHS -> RTO -> RHS each one must be
    % larger than previous but no larger than next. Stop when end of
    % shorter side is reached.
    % HS in same row. if a mismatch is encountered, register the bad index
    % and recurse starting from the bad.
    while lcur < size(left,1) & rcur < size(right,1)
        prevlhs = left(lcur,1);
        rhs = right(rcur,1);
        lto = left(lcur,3);
        lhs = left(lcur + 1,1);
        rto = right(rcur,3);
        if rto > lhs & lhs > lto & lto > rhs & rhs > prevlhs
            matched_lengths(m,:) = [right(rcur,2) left(lcur,2)];
            m = m + 1;
        else
            fprintf('\nproblem at %d left -- %d right:\nRTO: %d\tLHS: %d\tLTO: %d\tRHS: %d\tPREV-LTO: %d\n',...
                lcur,rcur,rto,lhs,lto,rhs,prevlhs...
            );
            if exist('matched_lengths','var')
                matched_lengths = [matched_lengths;AlignSteps(stage,rcur)];
            else
                matched_lengths = AlignSteps(stage,max(rcur,lcur));
            end
            break;
        end
        rcur = rcur + 1;
        lcur = lcur + 1;
    end
end   