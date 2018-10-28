function [matched_lengths] = AlignSteps(stage,rcop,lcop,start,datarate)
    % the stage of each side are assumed to be valid -- times are
    % correctly ordered: hs1 < to1 < hs2 < to2 ...
    % stage: 1 x [ RIGHT LEFT ] cell array. 
    % R and L are [ No. Steps ] x [ HS-INDEX LENGTH TO-INDEX] matrices.

    matched_lengths = double.empty(0,2);
    % recursion stop
    if start >= size(stage{1},1) || start >= size(stage{2},1)s        
        return;
    end
    m = 1;

    left = stage{2}(start:end,:);
    right = stage{1}(start:end,:);
    
    timeprox = datarate/3; % 3rd of a second -- maximal allowed time between consecutive lto - rhs and rto - lhs 
    
    % find where to start
    % sometimes it's like running, so instead of looking for the left TO
    % right after, look for the closest
    
%     while abs(right(rcur,1) - left(lcur,2)) > timeprox
%         rcur = rcur + 1;
%         % make sure we don't run out of data at this stage too
%         if rcur >= size(left,1) | rcur >= size(right,1)
%             matched_lengths = double.empty(0,2);
%             return;
%         end
%     end
    rcur = find(right(:,1) > left(1,2),1);
    % find the closest lto preferably after the found right heel strike
    [~,lcur] = min(abs(left(:,2) - right(rcur,1)));
%    lcur = lcur + start;
%     while left(lcur,2) <= right(rcur,1)
%         lcur = lcur + 1;
%     end
    
    % starting at 'cur', cycle through the hs/to data seeking the nearest appropriate entry
    % every time: RHS -> LTO -> LHS -> RTO -> RHS each one must be
    % larger than previous but no larger than next. Stop when end of
    % shorter side is reached.
    % HS in same row. if a mismatch is encountered, register the bad index
    % and recurse starting from the bad.
    isrunning = [];
    while lcur < size(left,1) & rcur < size(right,1)
        rhs = right(rcur,1);
        lto = left(lcur,2);
        lhs = left(lcur + 1,1);
        rto = right(rcur,2);
        % require  small difference between consecutive hs and to
        if all(abs([rto - lhs,lto - rhs])<timeprox)
            matched_lengths(m,:) = [lcop(lhs) - rcop(rto),rcop(rhs) - lcop(lto)];
            m = m + 1;
            % check for strict ordering of rto-lto,rhs-lhs 
            if rhs > lhs | lto > rto
                isrunning = [isrunning;[lcur,rcur]];
            end
        else
            fprintf('problem at %d left -- %d right:\nRTO: %d\tLHS: %d\tLTO: %d\tRHS: %d\n',...
                start+lcur,start+rcur,rto,lhs,lto,rhs...
            );
            if rcur == lcur == 1
                newstart = start + 1;
            else
                newstart = max(rcur,lcur);
            end
            if exist('matched_lengths','var')
                matched_lengths = [matched_lengths;AlignSteps(stage,rcop,lcop,newstart,datarate)];
            else
                matched_lengths = AlignSteps(stage,rcop,lcop,newstart,datarate);
            end
            break;
        end
        rcur = rcur + 1;
        lcur = lcur + 1;
    end
    if ~isempty(isrunning)
        warning('these steps look like like running in:');
        disp(isrunning);
    end
end   
