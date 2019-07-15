function m = afnn(x,tau,meanperiod)
%EMBDIMENSION Find Optimal Embedding Dimension for 1D vector x
%  using the false nearest neighbors technique, as explained in chapter 2
%  of this book:Modelling and Forecasting Financial Data Techniques of Nonlinear Dynamics
    maxd = 20;
    E = nan*ones(1,maxd);
    N = size(x,1);
    % pass 1: collect the nearest neighbor distances for every d in the
    % range
    nearests = ones(N,maxd)*nan;
    for d=1:maxd
        l = N - (d -1)*tau;
        nearest = ones(l,1)*nan;
        dd = lagmatrix(x,-tau*(0:d));
        for i=1:l
            pool = dd(1:l,:);
            for k=1:l
                if abs(k-i) <= meanperiod
                    pool(k,:) = inf*ones(1,size(dd,2));
                end
            end
            [~,mind] = min(vecnorm(pool - dd(i,:),2,2));
            nearest(i) = max(abs(dd(i,:)-dd(mind,:))); % max coordinate norm as in the paper
        end
        nearests(1:l,d) = nearest;
    end
    % pass  2: collect the mean nearest(d+1)/neareset(d) ratios
    for d=1:maxd -1
        E(d) = mean(nearests(1:N-d*tau,d+1) ./ nearests(1:N-d*tau,d));
    end
    Ehat = E(2:end)./E(1:end-1);
    figure;
    plot(Ehat)
    m = Ehat;
end

