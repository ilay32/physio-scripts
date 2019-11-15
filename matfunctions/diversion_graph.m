function [x,y] = diversion_graph(X,meanperiod,iter,dt)
%DIVERSION_GRAPH Return the Maximal Lyapunov Exponent of a Series
%   will apply the alogrithm described in Rosenstein 1993 to the input
%   series X. Names of arguments and variables are as in that paper:
%   https://pdfs.semanticscholar.org/c50a/0cf9d70d4a37855b0dea9d15d5515ecb6f76.pdf
%   this does not include the phase state embedding, but rather assumes
%   that X is already as X in the paper (M by m)
    lle = [];
    m = size(X,2);
    M = size(X,1);
    d0 = zeros(M,1); % these are the d_j(0)'s from the paper but just the pairing index their index
    if nargin == 3
        dt = 1;
    end
    %dji = nan*ones(iter,M);
    dji = [];
    % find the initial pairs
    for i=1:M
        %allinds = 1:M;
        %notinsamecycle = abs(allinds - i) > meanperiod;
        pool = X;
        for k=1:M
            if abs(k-i) <= meanperiod
                pool(k,:) = inf*ones(1,m);
            end
        end
        %[~,mind] = min(vecnorm(pool - X(i,:),2,2));
        [~,mind] = min(sqrt(sum((pool - X(i,:)).^2,2)));
        d0(i) = mind;
    end
    % follow every pair, as long as specified, taking the avergae of
    % the log of the subsequent distances
    for i=1:round(iter/dt)
        count = 0;
        av = 0;
        for j=1:M-i
            if j+i > M || d0(j)+i > M
                continue;
            end
            d = vnorm(X(j+i,:) - X(d0(j)+i,:));
            if d~=0 && ~isnan(d)
                av = av +log(d);
                count = count + 1;
            end
        end
        dji(i) = av/count;
    end
    y = dji;
    x = linspace(dt,iter,round(iter/dt));
    
