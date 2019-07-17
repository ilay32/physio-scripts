function [alpha,rsq] = dfa(x,plotflag,plottitle)
    %DFA.m computes the detrended fluctuation analysis of a given 1d array X
    % algorithm and optimal "boxes" by "An empirical examination of detrended fluctuation analysis for gait data",
    % Gait & Posture 31/3, 336-340. The paper's denotations are a little
    % mixed up. I follow Wikipedia's denotations: https://en.wikipedia.org/wiki/Detrended_fluctuation_analysis
    % as much as possible without compromising elegance.
    if nargin == 1
        plotflag = false;
    end
    alpha = nan;
    x = x(~isnan(x));
    N = length(x);
    boxfactor = 2^(1/8); % paper...
    if N/9 < 16*boxfactor % meaning there will be only one box
        disp('not enough data points');
        return;
    end
    mu = mean(x);
    X = nan*ones(N,1);
    box_sizes = 16;
    
    % compute optimal box sizes. this is the cheif concern of said paper    
    while box_sizes(end) < N/9
        box_sizes = [box_sizes;box_sizes(end)*boxfactor];
    end
     m = length(box_sizes);
    
    % generate the profile series
    for t=1:N
        X(t) = sum(x(1:t) - mu);
    end

    % steps 2 - 4 for every box
    for s=1:m
        n = floor(box_sizes(s));
        Yhat = [];
        for b=1:n:N
            % edge case
            if N-b < n
                % use the tail only if it's more than half way between the
                % previous window size and the current
                if N - b > n - (n - n/boxfactor)/2
                    % disp('including a slightly shorter last window')
                    n = N-b;
                else
                    % disp('skipping last');
                    continue;
                end
            end
            [~,~,resid] = regress(X(b+1:b+n),[ones(n,1),(b+1:b+n)']);
            Yhat = [Yhat;resid .^ 2]; % the residuals are the {X(t) - Y(t)} in Wikipedia's terms
        end
        F(s) = sqrt(sum(Yhat)/N); 
    end
    [b,~,~,~,stats] = regress(log2(F)',[ones(m,1),log2(box_sizes)]);
    alpha = b(2);
    rsq = stats(1);
    int = b(1);
    if plotflag
        wname = '';
        ntite = 'on';
        if nargin == 3
            wname = plottitle;
            ntite = 'off';
        end
        figure('Name',wname,'NumberTitle',ntite);
        scatter(log2(box_sizes),log2(F));
        hold on;
        plot(log2(box_sizes),log2(box_sizes)*alpha+int);
        ylabel('log fluctuation');
        xlabel('log window size');
        tite = sprintf('alpha = %f R^2 = %f',alpha,rsq);
        title(tite);
        hold off;
    end
end
