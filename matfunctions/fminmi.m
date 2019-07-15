function [minMi,minLag] = fminmi(x,maxlag,method,plotit)
%FMINMI Find first minimum of mutual information for [x(t),x(t+tau)]
%   will compute MI as H(x(t)) + H(x(t+tau)) - H(x(t),x(t+tau)) for taus from
%   1 to maxlag, which defaults to 10
    if nargin == 1
        maxlag = 50;
    end
    if  nargin < 4
        plotit = false;
    end
    if nargin==2 || (nargin > 2 && strcmp(method,'entropy2'))
        mis = zeros(1,maxlag);
        for tau=1:maxlag
            X = lagmatrix(x,[0,-tau]);
            v1 = X(1:end-tau,1);
            v2 = X(1:end-tau,2);
            mis(tau)= entropy(v1) + entropy(v2) - entropy2(v1',v2');
        end
    elseif strcmp(method,'swinney')
        [mis,~] = calcMutInfDelay(x,maxlag);
    end
    % now we have to find the "first minimum" which is really a rather
    % vague notion. I will find the first significant mininum like so:
    
    % 1. smooth the data a little
    smoothed = movmean(mis,3);
    
    % 2. find minima
    %[mins,minids ]  = findpeaks(-1*smoothed);
    
    % 3. find maxima
    %[maxs,maxids] = findpeaks(smoothed);
    
    % return the lowest minimum before the first max if exist, else the one
    % between the first and second max..
%     minMi = false;
%     minLag = false;
%     current_range = 1:1:maxids(1);
%     current_min = 1;
%     while ~minMi
%         considered = ismember(minids,current_range);
%         if any(considered)
%             [~,l] = max(mins(considered)); % we wanter the smaller one, but we flipped it for the findpeks...
%             minLag = minids(l);
%             minMi = mis(minids(l));
%         else
%             current_range = maxids(current_min):1:maxids(current_min + 1);
%             current_min = current_min + 1;
%         end
%     end
%     if ~minMi
%         warning("it seems that the MI by lag graph is totally flat. returning 1 as default");
%         minMi = mis(1);
%         minLag = 1;
%     end
    
    % a simpler approach, hoping this works everywhere lookup
    % MinPeakProminence for explanation
    [minMi,minLag] = findpeaks(-1*smoothed,'MinPeakProminence',abs(mean(diff(smoothed))));
    % and plot it to make sure if requested
    if plotit
        figure;
        hold on;
        plot(smoothed);
        plot(mis);
        plot(minLag,mis(minLag),'r*');
    end
    %return 1 value
    if length(minMi) > 1
        warning('more than one minimum MI found, using the first one');
        minMi = minMi(1);
        minLag = minLag(1);
    end
end

