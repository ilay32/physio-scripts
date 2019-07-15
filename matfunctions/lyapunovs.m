function [v,n] = lyapunovs(dgx,dgy,mp,dt,details)
    %LYAPUNOVS Various Max Lyapuno Estimates, 
    %  given the diversion grpaph, dg,
    %  of mean(log(distance)) 'dgy'  as a function of time 'dgx' difference
    %  as described in Rosenstien 1993.
    %  additional parameters for clearer plotting
    %  dt: the data frequency,
    % mp: the data mean period
    lle = [];
    figure('Name',sprintf('%s divergence graph %s %s',details.id,details.stagename,details.dname),'NumberTitle',false);
    scatter(dgx,dgy);
    hold on;

    % these are the various ranges on which the linear regression
    % could be applied
    rrange_half = round(mp/2);
    trendcenter= 0.9*max(dgy) + 0.1*dgy(1);
    [~,rrange_trnd] = min(abs(dgy - trendcenter));
    ranges = [rrange_half,mp,rrange_trnd];
    dolong = false;
    rrange_long = mp*10;
    if numel(dgx) > rrange_long
        ranges = [ranges,rrange_long];    
        dolong = true;
    else
        warning('not enough data points for long exponent estimation');
    end
    for i = 1:length(ranges)
        regfrom = 1;
        regto = ranges(i);
        if i == length(ranges) && dolong
            regfrom = mp*4;
        end
        [trend,~,~,~,~] = regress(dgy(regfrom:regto)',[ones(regto+1-regfrom,1),dgx(regfrom:regto)']);
        lambda1 = trend(2);
        const = trend(1);
        lh(i) = plot(dgx(regfrom:regto),lambda1*dgx(regfrom:regto)+const,'Linewidth',2);
        lle(i) = lambda1;
    end
    v = lle;
    ylm = get(gca,'YLim');
    for j=1:floor(length(dgx)/mp)
        cyclet = dgx(mp*j);
        line([cyclet,cyclet],ylm,'color','black','Linestyle', '--');
        text(cyclet+2*dt,ylm(1)+5*diff(ylm)/100,sprintf('cyc. %d',j));
    end
    lambdas = {'S','C','T'};
    lambdis = {1,2,3};
    n = {'short','one_cycle','trend_center','long','at_50'};
    if dolong
        lambdas = [lambdas {'L'}];
        lambdis = [lambdis {4}];
    else
        lle(strcmp(n,'long')) = nan;
    end
    lle = [lle,dgy(50)];
    v  = lle;
    fullambdas = cellfun(@(i,c)sprintf(['\\lambda_' c ' = %.3f'],lle(i)),lambdis,lambdas,'UniformOutput',false);
    fullambdas = [fullambdas {'divergence at 50'}];
    lh = [lh plot(dgx(50),dgy(50),'r*')];
    legend(lh,fullambdas);
    ylabel('mean(log(divergence)))');
    xlabel('seconds');
    grid on;
    title(sprintf('dimension: %d, lag: %d',...
        details.m,...
        details.tau...
    ));
end

